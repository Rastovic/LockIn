import 'package:drift/drift.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:vitals_core/vitals_core.dart';

import 'database.dart';

/// Reads and writes tasks, plans and stamps.
///
/// Rows in, domain types out. The engines never see a `TaskRow`, and the
/// database never sees a [Task], so neither has to change when the other does.
///
/// Every write fills the portability columns - `updatedAt`, `installId`, and a
/// UUID `id` - because a row written without them cannot be backed up or
/// merged, and that is not something to leave to a caller's memory.
final class TaskRepository {
  const TaskRepository(this.db, {required this.installId});

  final TallyDatabase db;
  final String installId;

  // --- tasks ---------------------------------------------------------------

  /// Every task that has not been deleted.
  ///
  /// Archived tasks are included: archiving hides a task from the lists without
  /// destroying its history, and the caller decides whether to show it.
  Future<List<Task>> tasks() async {
    final rows = await (db.select(db.tasks)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .get();
    return rows.map(_toTask).toList();
  }

  Future<Task?> taskById(String id) async {
    final row = await (db.select(db.tasks)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toTask(row);
  }

  /// Creates a task and returns it.
  Future<Task> createTask({
    required TaskKind kind,
    required String title,
    required DateTime now,
    String? stickerId,
    int? estimateMinutes,
    String? projectId,
    String? note,
    TaskRepeat repeat = TaskRepeat.once,
    bool needsSorting = false,
    Set<int> habitWeekdays = const {},
  }) async {
    final task = Task(
      id: Ids.newId(),
      kind: kind,
      title: title.trim(),
      createdAt: now,
      repeat: repeat,
      needsSorting: needsSorting,
      note: note,
      stickerId: stickerId,
      estimateMinutes: estimateMinutes,
      projectId: projectId,
      habitWeekdays: habitWeekdays,
    );

    await db.into(db.tasks).insert(
          TasksCompanion.insert(
            id: task.id,
            updatedAt: now.millisecondsSinceEpoch,
            installId: installId,
            kind: task.kind.name,
            title: task.title,
            createdAt: now.millisecondsSinceEpoch,
            repeat: Value(task.repeat.name),
            needsSorting: Value(task.needsSorting),
            note: Value(task.note),
            stickerId: Value(task.stickerId),
            estimateMinutes: Value(task.estimateMinutes),
            projectId: Value(task.projectId),
            habitWeekdays: Value(_encodeWeekdays(task.habitWeekdays)),
          ),
        );
    return task;
  }

  Future<void> updateTask(Task task, {required DateTime now}) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(task.id))).write(
      TasksCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        kind: Value(task.kind.name),
        title: Value(task.title.trim()),
        repeat: Value(task.repeat.name),
        needsSorting: Value(task.needsSorting),
        note: Value(task.note),
        stickerId: Value(task.stickerId),
        estimateMinutes: Value(task.estimateMinutes),
        habitWeekdays: Value(_encodeWeekdays(task.habitWeekdays)),
        lastCompletedAt: Value(task.lastCompletedAt?.millisecondsSinceEpoch),
        archivedAt: Value(task.archivedAt?.millisecondsSinceEpoch),
      ),
    );
  }

  /// Soft-deletes a task.
  ///
  /// **A tombstone, never a removal.** A row that vanishes without one comes
  /// back to life on the next merge, and history that referenced it loses its
  /// name. Plan entries pointing at it are tombstoned in the same transaction
  /// so nothing is left dangling.
  Future<void> deleteTask(String id, {required DateTime now}) async {
    final stamp = now.millisecondsSinceEpoch;
    await db.transaction(() async {
      await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          deletedAt: Value(stamp),
          updatedAt: Value(stamp),
        ),
      );
      await (db.update(db.planEntries)..where((t) => t.taskId.equals(id)))
          .write(
        PlanEntriesCompanion(
          deletedAt: Value(stamp),
          updatedAt: Value(stamp),
        ),
      );
    });
  }

  /// Archives a task: hidden from the lists, history intact.
  Future<void> archiveTask(String id, {required DateTime now}) async {
    await (db.update(db.tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        archivedAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  // --- the day's plan ------------------------------------------------------

  Future<List<PlanEntry>> planFor(String dayKey) async {
    final rows = await (db.select(db.planEntries)
          ..where((t) => t.dayKey.equals(dayKey))
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]))
        .get();
    return rows.map(_toPlanEntry).toList();
  }

  /// Persists a plan wholesale.
  ///
  /// The planner is a pure function over a list, so the simplest correct thing
  /// is to hand back the list it produced. Rows absent from [entries] are
  /// tombstoned rather than deleted, which is what makes a removal survive a
  /// merge.
  Future<void> savePlan({
    required String dayKey,
    required List<PlanEntry> entries,
    required DateTime now,
  }) async {
    final stamp = now.millisecondsSinceEpoch;
    final offset = now.timeZoneOffset.inMinutes;
    final keep = {for (final entry in entries) entry.id};

    await db.transaction(() async {
      final existing = await (db.select(db.planEntries)
            ..where((t) => t.dayKey.equals(dayKey)))
          .get();
      final known = {for (final row in existing) row.id};

      for (final row in existing) {
        if (keep.contains(row.id)) continue;
        await (db.update(db.planEntries)..where((t) => t.id.equals(row.id)))
            .write(
          PlanEntriesCompanion(
            deletedAt: Value(stamp),
            updatedAt: Value(stamp),
          ),
        );
      }

      for (final entry in entries) {
        if (known.contains(entry.id)) {
          await (db.update(db.planEntries)..where((t) => t.id.equals(entry.id)))
              .write(
            PlanEntriesCompanion(
              updatedAt: Value(stamp),
              sortOrder: Value(entry.sortOrder),
              doneAt: Value(entry.doneAt?.millisecondsSinceEpoch),
              deletedAt: const Value(null),
            ),
          );
        } else {
          await db.into(db.planEntries).insert(
                PlanEntriesCompanion.insert(
                  id: entry.id,
                  updatedAt: stamp,
                  installId: installId,
                  dayKey: entry.dayKey,
                  tzOffsetMinutes: offset,
                  taskId: entry.taskId,
                  sortOrder: entry.sortOrder,
                  source: entry.source.name,
                  doneAt: Value(entry.doneAt?.millisecondsSinceEpoch),
                ),
              );
        }
      }
    });
  }

  // --- stickers ------------------------------------------------------------

  /// Records a stamp.
  ///
  /// Append-only, and it never touches the ledger. The separation between the
  /// two currencies is enforced by there being no code path from here to a
  /// balance.
  Future<void> addStamp(StickerStamp stamp, {required DateTime now}) async {
    await db.into(db.stickerStamps).insert(
          StickerStampsCompanion.insert(
            id: stamp.id,
            updatedAt: now.millisecondsSinceEpoch,
            installId: installId,
            dayKey: stamp.dayKey,
            tzOffsetMinutes: now.timeZoneOffset.inMinutes,
            stickerId: stamp.stickerId,
            taskId: stamp.taskId,
            stampedAt: stamp.at.millisecondsSinceEpoch,
          ),
        );
  }

  /// Removes the stamps a task earned on a day.
  ///
  /// Unticking is a mis-tap correction and must cost nothing, including on the
  /// sticker sheet.
  Future<void> removeStampsFor({
    required String taskId,
    required String dayKey,
    required DateTime now,
  }) async {
    await (db.update(db.stickerStamps)
          ..where((t) => t.taskId.equals(taskId) & t.dayKey.equals(dayKey)))
        .write(
      StickerStampsCompanion(
        deletedAt: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  Future<List<StickerStamp>> stampsFor(String dayKey) async {
    final rows = await (db.select(db.stickerStamps)
          ..where((t) => t.dayKey.equals(dayKey))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    return [
      for (final row in rows)
        StickerStamp(
          id: row.id,
          dayKey: row.dayKey,
          stickerId: row.stickerId,
          taskId: row.taskId,
          at: DateTime.fromMillisecondsSinceEpoch(row.stampedAt, isUtc: true),
        ),
    ];
  }

  // --- sessions ------------------------------------------------------------

  /// Stores a finished focus block.
  Future<void> addSession(
    FocusSession session, {
    required String dayKey,
    required DateTime now,
  }) async {
    await db.into(db.sessions).insert(
          SessionsCompanion.insert(
            id: session.id,
            updatedAt: now.millisecondsSinceEpoch,
            installId: installId,
            dayKey: dayKey,
            tzOffsetMinutes: now.timeZoneOffset.inMinutes,
            startedAt: session.startedAt.millisecondsSinceEpoch,
            endedAt: session.endedAt.millisecondsSinceEpoch,
            taskId: Value(session.taskId),
            phoneDownVerified: Value(session.phoneDownVerified),
          ),
        );
  }

  /// Stores the minutes a tick paid, under an id the caller derives from the
  /// plan entry so an untick can find it again.
  ///
  /// An upsert rather than an insert: ticking, unticking and ticking again
  /// reuses the id, and the second tick has to revive the tombstoned row
  /// instead of colliding with it.
  Future<void> putTickSession(
    FocusSession session, {
    required String dayKey,
    required DateTime now,
  }) async {
    await db.into(db.sessions).insertOnConflictUpdate(
          SessionsCompanion.insert(
            id: session.id,
            updatedAt: now.millisecondsSinceEpoch,
            installId: installId,
            dayKey: dayKey,
            tzOffsetMinutes: now.timeZoneOffset.inMinutes,
            startedAt: session.startedAt.millisecondsSinceEpoch,
            endedAt: session.endedAt.millisecondsSinceEpoch,
            taskId: Value(session.taskId),
            phoneDownVerified: const Value(false),
            deletedAt: const Value(null),
          ),
        );
  }

  /// Tombstones one session. A no-op when there is none by that id.
  Future<void> removeSession(String id, {required DateTime now}) async {
    final stamp = now.millisecondsSinceEpoch;
    await (db.update(db.sessions)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.deletedAt.isNull()))
        .write(
      SessionsCompanion(deletedAt: Value(stamp), updatedAt: Value(stamp)),
    );
  }

  /// Seconds already focused on [taskId] during [dayKey], leaving out the
  /// session with id [excludeId].
  Future<int> focusedSecondsFor({
    required String taskId,
    required String dayKey,
    String? excludeId,
  }) async {
    final rows = await (db.select(db.sessions)
          ..where((t) => t.taskId.equals(taskId))
          ..where((t) => t.dayKey.equals(dayKey))
          ..where((t) => t.deletedAt.isNull()))
        .get();
    var total = 0;
    for (final row in rows) {
      if (row.id == excludeId) continue;
      total += ((row.endedAt - row.startedAt) / 1000).floor();
    }
    return total;
  }

  /// Current streak per habit, counted back from [dayKey].
  ///
  /// A streak is derived from the plan rather than stored, on the same rule as
  /// everything else here: a stored counter drifts, and a derived one cannot.
  Future<Map<String, int>> habitStreaks({
    required String dayKey,
    int lookBackDays = 400,
  }) async {
    final from = addDays(dayKey, -lookBackDays);
    final rows = await (db.select(db.planEntries)
          ..where((t) => t.dayKey.isBetweenValues(from, dayKey))
          ..where((t) => t.deletedAt.isNull()))
        .get();

    final doneDays = <String, Set<String>>{};
    for (final row in rows) {
      if (row.doneAt == null) continue;
      doneDays.putIfAbsent(row.taskId, () => {}).add(row.dayKey);
    }

    final streaks = <String, int>{};
    for (final entry in doneDays.entries) {
      var streak = 0;
      // Today not being done yet does not break a streak: the day is still
      // running. Counting starts from yesterday in that case.
      var cursor = entry.value.contains(dayKey) ? dayKey : addDays(dayKey, -1);
      while (entry.value.contains(cursor)) {
        streak++;
        cursor = addDays(cursor, -1);
      }
      if (streak > 0) streaks[entry.key] = streak;
    }
    return streaks;
  }

  // --- conversions ---------------------------------------------------------

  Task _toTask(TaskRow row) => Task(
        id: row.id,
        // An unknown kind from a newer version degrades to a one-off rather
        // than crashing the list. Rule 6 keeps enums as strings precisely so
        // this stays a recoverable situation.
        kind: TaskKind.values.firstWhere(
          (k) => k.name == row.kind,
          orElse: () => TaskKind.oneoff,
        ),
        title: row.title,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
        note: row.note,
        // A null is a task written before repeating existed, and every one of
        // those was a one-off. An unknown value from a newer version reads the
        // same way rather than crashing a launch.
        needsSorting: row.needsSorting ?? false,
        repeat: TaskRepeat.values.firstWhere(
          (r) => r.name == row.repeat,
          orElse: () => TaskRepeat.once,
        ),
        stickerId: row.stickerId,
        estimateMinutes: row.estimateMinutes,
        projectId: row.projectId,
        habitWeekdays: _decodeWeekdays(row.habitWeekdays),
        lastCompletedAt: row.lastCompletedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                row.lastCompletedAt!,
                isUtc: true,
              ),
        archivedAt: row.archivedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true),
      );

  PlanEntry _toPlanEntry(PlanEntryRow row) => PlanEntry(
        id: row.id,
        dayKey: row.dayKey,
        taskId: row.taskId,
        sortOrder: row.sortOrder,
        source: PlanSource.values.firstWhere(
          (s) => s.name == row.source,
          orElse: () => PlanSource.manual,
        ),
        doneAt: row.doneAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.doneAt!, isUtc: true),
      );

  static String _encodeWeekdays(Set<int> days) =>
      (days.toList()..sort()).join(',');

  static Set<int> _decodeWeekdays(String encoded) => {
        for (final part in encoded.split(','))
          if (int.tryParse(part.trim()) case final day?)
            if (day >= 1 && day <= 7) day,
      };
}

/// Projects: the folders that project tasks are filed under.
///
/// Separate from [TaskRepository] because a project is not a task and reads
/// nothing from the plan. Kept in this file because the two are always used
/// together and a one-class file would be filing for its own sake.
final class ProjectRepository {
  ProjectRepository(this.db, {required this.installId});

  final TallyDatabase db;
  final String installId;

  Future<List<Project>> projects() async {
    final rows = await (db.select(db.projects)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return [for (final row in rows) _toProject(row)];
  }

  Future<Project> createProject({
    required String name,
    required DateTime now,
    String? stickerId,
  }) async {
    final project = Project(
      id: Ids.newId(),
      name: name.trim(),
      createdAt: now,
      stickerId: stickerId,
    );
    await db.into(db.projects).insert(
          ProjectsCompanion.insert(
            id: project.id,
            updatedAt: now.millisecondsSinceEpoch,
            installId: installId,
            name: project.name,
            createdAt: now.millisecondsSinceEpoch,
            stickerId: Value(project.stickerId),
          ),
        );
    return project;
  }

  Future<void> updateProject(Project project, {required DateTime now}) async {
    await (db.update(db.projects)..where((t) => t.id.equals(project.id))).write(
      ProjectsCompanion(
        updatedAt: Value(now.millisecondsSinceEpoch),
        name: Value(project.name.trim()),
        stickerId: Value(project.stickerId),
        archivedAt: Value(project.archivedAt?.millisecondsSinceEpoch),
      ),
    );
  }

  /// Removes a project and unfiles its tasks.
  ///
  /// **The tasks survive.** Deleting a folder is not a decision to destroy
  /// what is in it, and someone tidying up their project list would not expect
  /// to lose the work. They become ordinary project tasks with no project.
  Future<void> deleteProject(String id, {required DateTime now}) async {
    final stamp = now.millisecondsSinceEpoch;
    await db.transaction(() async {
      await (db.update(db.tasks)..where((t) => t.projectId.equals(id))).write(
        TasksCompanion(
          updatedAt: Value(stamp),
          projectId: const Value(null),
        ),
      );
      await (db.update(db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(
          updatedAt: Value(stamp),
          deletedAt: Value(stamp),
        ),
      );
    });
  }

  Project _toProject(ProjectRow row) => Project(
        id: row.id,
        name: row.name,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row.createdAt, isUtc: true),
        stickerId: row.stickerId,
        archivedAt: row.archivedAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(row.archivedAt!, isUtc: true),
      );
}
