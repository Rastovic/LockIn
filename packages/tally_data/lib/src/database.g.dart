// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stickerIdMeta = const VerificationMeta(
    'stickerId',
  );
  @override
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
    'sticker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estimateMinutesMeta = const VerificationMeta(
    'estimateMinutes',
  );
  @override
  late final GeneratedColumn<int> estimateMinutes = GeneratedColumn<int>(
    'estimate_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _habitWeekdaysMeta = const VerificationMeta(
    'habitWeekdays',
  );
  @override
  late final GeneratedColumn<String> habitWeekdays = GeneratedColumn<String>(
    'habit_weekdays',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastCompletedAtMeta = const VerificationMeta(
    'lastCompletedAt',
  );
  @override
  late final GeneratedColumn<int> lastCompletedAt = GeneratedColumn<int>(
    'last_completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    kind,
    title,
    stickerId,
    estimateMinutes,
    projectId,
    habitWeekdays,
    createdAt,
    lastCompletedAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('sticker_id')) {
      context.handle(
        _stickerIdMeta,
        stickerId.isAcceptableOrUnknown(data['sticker_id']!, _stickerIdMeta),
      );
    }
    if (data.containsKey('estimate_minutes')) {
      context.handle(
        _estimateMinutesMeta,
        estimateMinutes.isAcceptableOrUnknown(
          data['estimate_minutes']!,
          _estimateMinutesMeta,
        ),
      );
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('habit_weekdays')) {
      context.handle(
        _habitWeekdaysMeta,
        habitWeekdays.isAcceptableOrUnknown(
          data['habit_weekdays']!,
          _habitWeekdaysMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_completed_at')) {
      context.handle(
        _lastCompletedAtMeta,
        lastCompletedAt.isAcceptableOrUnknown(
          data['last_completed_at']!,
          _lastCompletedAtMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      stickerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sticker_id'],
      ),
      estimateMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}estimate_minutes'],
      ),
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      habitWeekdays: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_weekdays'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      lastCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_completed_at'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `habit` / `projectTask` / `dread` / `oneoff`.
  final String kind;
  final String title;
  final String? stickerId;
  final int? estimateMinutes;
  final String? projectId;

  /// ISO weekdays a habit is due, as `1,3,5`. Empty means every day.
  final String habitWeekdays;
  final int createdAt;
  final int? lastCompletedAt;
  final int? archivedAt;
  const Task({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.kind,
    required this.title,
    this.stickerId,
    this.estimateMinutes,
    this.projectId,
    required this.habitWeekdays,
    required this.createdAt,
    this.lastCompletedAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['kind'] = Variable<String>(kind);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || stickerId != null) {
      map['sticker_id'] = Variable<String>(stickerId);
    }
    if (!nullToAbsent || estimateMinutes != null) {
      map['estimate_minutes'] = Variable<int>(estimateMinutes);
    }
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    map['habit_weekdays'] = Variable<String>(habitWeekdays);
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || lastCompletedAt != null) {
      map['last_completed_at'] = Variable<int>(lastCompletedAt);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      kind: Value(kind),
      title: Value(title),
      stickerId: stickerId == null && nullToAbsent
          ? const Value.absent()
          : Value(stickerId),
      estimateMinutes: estimateMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(estimateMinutes),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      habitWeekdays: Value(habitWeekdays),
      createdAt: Value(createdAt),
      lastCompletedAt: lastCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String>(json['title']),
      stickerId: serializer.fromJson<String?>(json['stickerId']),
      estimateMinutes: serializer.fromJson<int?>(json['estimateMinutes']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      habitWeekdays: serializer.fromJson<String>(json['habitWeekdays']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      lastCompletedAt: serializer.fromJson<int?>(json['lastCompletedAt']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String>(title),
      'stickerId': serializer.toJson<String?>(stickerId),
      'estimateMinutes': serializer.toJson<int?>(estimateMinutes),
      'projectId': serializer.toJson<String?>(projectId),
      'habitWeekdays': serializer.toJson<String>(habitWeekdays),
      'createdAt': serializer.toJson<int>(createdAt),
      'lastCompletedAt': serializer.toJson<int?>(lastCompletedAt),
      'archivedAt': serializer.toJson<int?>(archivedAt),
    };
  }

  Task copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? kind,
    String? title,
    Value<String?> stickerId = const Value.absent(),
    Value<int?> estimateMinutes = const Value.absent(),
    Value<String?> projectId = const Value.absent(),
    String? habitWeekdays,
    int? createdAt,
    Value<int?> lastCompletedAt = const Value.absent(),
    Value<int?> archivedAt = const Value.absent(),
  }) => Task(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    kind: kind ?? this.kind,
    title: title ?? this.title,
    stickerId: stickerId.present ? stickerId.value : this.stickerId,
    estimateMinutes: estimateMinutes.present
        ? estimateMinutes.value
        : this.estimateMinutes,
    projectId: projectId.present ? projectId.value : this.projectId,
    habitWeekdays: habitWeekdays ?? this.habitWeekdays,
    createdAt: createdAt ?? this.createdAt,
    lastCompletedAt: lastCompletedAt.present
        ? lastCompletedAt.value
        : this.lastCompletedAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      stickerId: data.stickerId.present ? data.stickerId.value : this.stickerId,
      estimateMinutes: data.estimateMinutes.present
          ? data.estimateMinutes.value
          : this.estimateMinutes,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      habitWeekdays: data.habitWeekdays.present
          ? data.habitWeekdays.value
          : this.habitWeekdays,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastCompletedAt: data.lastCompletedAt.present
          ? data.lastCompletedAt.value
          : this.lastCompletedAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('stickerId: $stickerId, ')
          ..write('estimateMinutes: $estimateMinutes, ')
          ..write('projectId: $projectId, ')
          ..write('habitWeekdays: $habitWeekdays, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    kind,
    title,
    stickerId,
    estimateMinutes,
    projectId,
    habitWeekdays,
    createdAt,
    lastCompletedAt,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.stickerId == this.stickerId &&
          other.estimateMinutes == this.estimateMinutes &&
          other.projectId == this.projectId &&
          other.habitWeekdays == this.habitWeekdays &&
          other.createdAt == this.createdAt &&
          other.lastCompletedAt == this.lastCompletedAt &&
          other.archivedAt == this.archivedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> kind;
  final Value<String> title;
  final Value<String?> stickerId;
  final Value<int?> estimateMinutes;
  final Value<String?> projectId;
  final Value<String> habitWeekdays;
  final Value<int> createdAt;
  final Value<int?> lastCompletedAt;
  final Value<int?> archivedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.estimateMinutes = const Value.absent(),
    this.projectId = const Value.absent(),
    this.habitWeekdays = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastCompletedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String kind,
    required String title,
    this.stickerId = const Value.absent(),
    this.estimateMinutes = const Value.absent(),
    this.projectId = const Value.absent(),
    this.habitWeekdays = const Value.absent(),
    required int createdAt,
    this.lastCompletedAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       kind = Value(kind),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<String>? stickerId,
    Expression<int>? estimateMinutes,
    Expression<String>? projectId,
    Expression<String>? habitWeekdays,
    Expression<int>? createdAt,
    Expression<int>? lastCompletedAt,
    Expression<int>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (stickerId != null) 'sticker_id': stickerId,
      if (estimateMinutes != null) 'estimate_minutes': estimateMinutes,
      if (projectId != null) 'project_id': projectId,
      if (habitWeekdays != null) 'habit_weekdays': habitWeekdays,
      if (createdAt != null) 'created_at': createdAt,
      if (lastCompletedAt != null) 'last_completed_at': lastCompletedAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? kind,
    Value<String>? title,
    Value<String?>? stickerId,
    Value<int?>? estimateMinutes,
    Value<String?>? projectId,
    Value<String>? habitWeekdays,
    Value<int>? createdAt,
    Value<int?>? lastCompletedAt,
    Value<int?>? archivedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      stickerId: stickerId ?? this.stickerId,
      estimateMinutes: estimateMinutes ?? this.estimateMinutes,
      projectId: projectId ?? this.projectId,
      habitWeekdays: habitWeekdays ?? this.habitWeekdays,
      createdAt: createdAt ?? this.createdAt,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (estimateMinutes.present) {
      map['estimate_minutes'] = Variable<int>(estimateMinutes.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (habitWeekdays.present) {
      map['habit_weekdays'] = Variable<String>(habitWeekdays.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (lastCompletedAt.present) {
      map['last_completed_at'] = Variable<int>(lastCompletedAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('stickerId: $stickerId, ')
          ..write('estimateMinutes: $estimateMinutes, ')
          ..write('projectId: $projectId, ')
          ..write('habitWeekdays: $habitWeekdays, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastCompletedAt: $lastCompletedAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stickerIdMeta = const VerificationMeta(
    'stickerId',
  );
  @override
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
    'sticker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    name,
    stickerId,
    createdAt,
    archivedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<Project> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sticker_id')) {
      context.handle(
        _stickerIdMeta,
        stickerId.isAcceptableOrUnknown(data['sticker_id']!, _stickerIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      stickerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sticker_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}archived_at'],
      ),
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;
  final String name;
  final String? stickerId;
  final int createdAt;
  final int? archivedAt;
  const Project({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.name,
    this.stickerId,
    required this.createdAt,
    this.archivedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || stickerId != null) {
      map['sticker_id'] = Variable<String>(stickerId);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      name: Value(name),
      stickerId: stickerId == null && nullToAbsent
          ? const Value.absent()
          : Value(stickerId),
      createdAt: Value(createdAt),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
    );
  }

  factory Project.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      name: serializer.fromJson<String>(json['name']),
      stickerId: serializer.fromJson<String?>(json['stickerId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'name': serializer.toJson<String>(name),
      'stickerId': serializer.toJson<String?>(stickerId),
      'createdAt': serializer.toJson<int>(createdAt),
      'archivedAt': serializer.toJson<int?>(archivedAt),
    };
  }

  Project copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? name,
    Value<String?> stickerId = const Value.absent(),
    int? createdAt,
    Value<int?> archivedAt = const Value.absent(),
  }) => Project(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    name: name ?? this.name,
    stickerId: stickerId.present ? stickerId.value : this.stickerId,
    createdAt: createdAt ?? this.createdAt,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
  );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      name: data.name.present ? data.name.value : this.name,
      stickerId: data.stickerId.present ? data.stickerId.value : this.stickerId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('name: $name, ')
          ..write('stickerId: $stickerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    name,
    stickerId,
    createdAt,
    archivedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.name == this.name &&
          other.stickerId == this.stickerId &&
          other.createdAt == this.createdAt &&
          other.archivedAt == this.archivedAt);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> name;
  final Value<String?> stickerId;
  final Value<int> createdAt;
  final Value<int?> archivedAt;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.name = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String name,
    this.stickerId = const Value.absent(),
    required int createdAt,
    this.archivedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Project> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? name,
    Expression<String>? stickerId,
    Expression<int>? createdAt,
    Expression<int>? archivedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (name != null) 'name': name,
      if (stickerId != null) 'sticker_id': stickerId,
      if (createdAt != null) 'created_at': createdAt,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? name,
    Value<String?>? stickerId,
    Value<int>? createdAt,
    Value<int?>? archivedAt,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      name: name ?? this.name,
      stickerId: stickerId ?? this.stickerId,
      createdAt: createdAt ?? this.createdAt,
      archivedAt: archivedAt ?? this.archivedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('name: $name, ')
          ..write('stickerId: $stickerId, ')
          ..write('createdAt: $createdAt, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
    'ended_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _phoneDownVerifiedMeta = const VerificationMeta(
    'phoneDownVerified',
  );
  @override
  late final GeneratedColumn<bool> phoneDownVerified = GeneratedColumn<bool>(
    'phone_down_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("phone_down_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    taskId,
    startedAt,
    endedAt,
    phoneDownVerified,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_endedAtMeta);
    }
    if (data.containsKey('phone_down_verified')) {
      context.handle(
        _phoneDownVerifiedMeta,
        phoneDownVerified.isAcceptableOrUnknown(
          data['phone_down_verified']!,
          _phoneDownVerifiedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ended_at'],
      )!,
      phoneDownVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}phone_down_verified'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;
  final String? taskId;
  final int startedAt;
  final int endedAt;

  /// Screen stayed off for the whole block, so the block pays 1.5x.
  final bool phoneDownVerified;
  const Session({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    this.taskId,
    required this.startedAt,
    required this.endedAt,
    required this.phoneDownVerified,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    map['started_at'] = Variable<int>(startedAt);
    map['ended_at'] = Variable<int>(endedAt);
    map['phone_down_verified'] = Variable<bool>(phoneDownVerified);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      startedAt: Value(startedAt),
      endedAt: Value(endedAt),
      phoneDownVerified: Value(phoneDownVerified),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int>(json['endedAt']),
      phoneDownVerified: serializer.fromJson<bool>(json['phoneDownVerified']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'taskId': serializer.toJson<String?>(taskId),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int>(endedAt),
      'phoneDownVerified': serializer.toJson<bool>(phoneDownVerified),
    };
  }

  Session copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    Value<String?> taskId = const Value.absent(),
    int? startedAt,
    int? endedAt,
    bool? phoneDownVerified,
  }) => Session(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    taskId: taskId.present ? taskId.value : this.taskId,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    phoneDownVerified: phoneDownVerified ?? this.phoneDownVerified,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      phoneDownVerified: data.phoneDownVerified.present
          ? data.phoneDownVerified.value
          : this.phoneDownVerified,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('taskId: $taskId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('phoneDownVerified: $phoneDownVerified')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    taskId,
    startedAt,
    endedAt,
    phoneDownVerified,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.taskId == this.taskId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.phoneDownVerified == this.phoneDownVerified);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<String?> taskId;
  final Value<int> startedAt;
  final Value<int> endedAt;
  final Value<bool> phoneDownVerified;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.taskId = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.phoneDownVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    this.taskId = const Value.absent(),
    required int startedAt,
    required int endedAt,
    this.phoneDownVerified = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       startedAt = Value(startedAt),
       endedAt = Value(endedAt);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<String>? taskId,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<bool>? phoneDownVerified,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (taskId != null) 'task_id': taskId,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (phoneDownVerified != null) 'phone_down_verified': phoneDownVerified,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<String?>? taskId,
    Value<int>? startedAt,
    Value<int>? endedAt,
    Value<bool>? phoneDownVerified,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      taskId: taskId ?? this.taskId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      phoneDownVerified: phoneDownVerified ?? this.phoneDownVerified,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (phoneDownVerified.present) {
      map['phone_down_verified'] = Variable<bool>(phoneDownVerified.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('taskId: $taskId, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('phoneDownVerified: $phoneDownVerified, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PlanEntriesTable extends PlanEntries
    with TableInfo<$PlanEntriesTable, PlanEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlanEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _doneAtMeta = const VerificationMeta('doneAt');
  @override
  late final GeneratedColumn<int> doneAt = GeneratedColumn<int>(
    'done_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    taskId,
    sortOrder,
    source,
    doneAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'plan_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlanEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('done_at')) {
      context.handle(
        _doneAtMeta,
        doneAt.isAcceptableOrUnknown(data['done_at']!, _doneAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlanEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlanEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      doneAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}done_at'],
      ),
    );
  }

  @override
  $PlanEntriesTable createAlias(String alias) {
    return $PlanEntriesTable(attachedDatabase, alias);
  }
}

class PlanEntry extends DataClass implements Insertable<PlanEntry> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;
  final String taskId;

  /// Explicit, because id order is not an ordering: UUID v7 only sorts across
  /// milliseconds, and two rows added in one tap can share one.
  final int sortOrder;

  /// `manual` / `habit` / `suggestion`. Kept because the split of where your
  /// day actually came from is one query and is genuinely interesting.
  final String source;
  final int? doneAt;
  const PlanEntry({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    required this.taskId,
    required this.sortOrder,
    required this.source,
    this.doneAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['task_id'] = Variable<String>(taskId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || doneAt != null) {
      map['done_at'] = Variable<int>(doneAt);
    }
    return map;
  }

  PlanEntriesCompanion toCompanion(bool nullToAbsent) {
    return PlanEntriesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      taskId: Value(taskId),
      sortOrder: Value(sortOrder),
      source: Value(source),
      doneAt: doneAt == null && nullToAbsent
          ? const Value.absent()
          : Value(doneAt),
    );
  }

  factory PlanEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlanEntry(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      taskId: serializer.fromJson<String>(json['taskId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      source: serializer.fromJson<String>(json['source']),
      doneAt: serializer.fromJson<int?>(json['doneAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'taskId': serializer.toJson<String>(taskId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'source': serializer.toJson<String>(source),
      'doneAt': serializer.toJson<int?>(doneAt),
    };
  }

  PlanEntry copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    String? taskId,
    int? sortOrder,
    String? source,
    Value<int?> doneAt = const Value.absent(),
  }) => PlanEntry(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    taskId: taskId ?? this.taskId,
    sortOrder: sortOrder ?? this.sortOrder,
    source: source ?? this.source,
    doneAt: doneAt.present ? doneAt.value : this.doneAt,
  );
  PlanEntry copyWithCompanion(PlanEntriesCompanion data) {
    return PlanEntry(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      source: data.source.present ? data.source.value : this.source,
      doneAt: data.doneAt.present ? data.doneAt.value : this.doneAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlanEntry(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('taskId: $taskId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('source: $source, ')
          ..write('doneAt: $doneAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    taskId,
    sortOrder,
    source,
    doneAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlanEntry &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.taskId == this.taskId &&
          other.sortOrder == this.sortOrder &&
          other.source == this.source &&
          other.doneAt == this.doneAt);
}

class PlanEntriesCompanion extends UpdateCompanion<PlanEntry> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<String> taskId;
  final Value<int> sortOrder;
  final Value<String> source;
  final Value<int?> doneAt;
  final Value<int> rowid;
  const PlanEntriesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.taskId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.source = const Value.absent(),
    this.doneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PlanEntriesCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    required String taskId,
    required int sortOrder,
    required String source,
    this.doneAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       taskId = Value(taskId),
       sortOrder = Value(sortOrder),
       source = Value(source);
  static Insertable<PlanEntry> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<String>? taskId,
    Expression<int>? sortOrder,
    Expression<String>? source,
    Expression<int>? doneAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (taskId != null) 'task_id': taskId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (source != null) 'source': source,
      if (doneAt != null) 'done_at': doneAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PlanEntriesCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<String>? taskId,
    Value<int>? sortOrder,
    Value<String>? source,
    Value<int?>? doneAt,
    Value<int>? rowid,
  }) {
    return PlanEntriesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      taskId: taskId ?? this.taskId,
      sortOrder: sortOrder ?? this.sortOrder,
      source: source ?? this.source,
      doneAt: doneAt ?? this.doneAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (doneAt.present) {
      map['done_at'] = Variable<int>(doneAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlanEntriesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('taskId: $taskId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('source: $source, ')
          ..write('doneAt: $doneAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WatchedAppsTable extends WatchedApps
    with TableInfo<$WatchedAppsTable, WatchedApp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchedAppsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _watchingMeta = const VerificationMeta(
    'watching',
  );
  @override
  late final GeneratedColumn<bool> watching = GeneratedColumn<bool>(
    'watching',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("watching" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _removedAtMeta = const VerificationMeta(
    'removedAt',
  );
  @override
  late final GeneratedColumn<int> removedAt = GeneratedColumn<int>(
    'removed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notInstalledMeta = const VerificationMeta(
    'notInstalled',
  );
  @override
  late final GeneratedColumn<bool> notInstalled = GeneratedColumn<bool>(
    'not_installed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("not_installed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    packageName,
    label,
    watching,
    addedAt,
    removedAt,
    notInstalled,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watched_apps';
  @override
  VerificationContext validateIntegrity(
    Insertable<WatchedApp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('watching')) {
      context.handle(
        _watchingMeta,
        watching.isAcceptableOrUnknown(data['watching']!, _watchingMeta),
      );
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('removed_at')) {
      context.handle(
        _removedAtMeta,
        removedAt.isAcceptableOrUnknown(data['removed_at']!, _removedAtMeta),
      );
    }
    if (data.containsKey('not_installed')) {
      context.handle(
        _notInstalledMeta,
        notInstalled.isAcceptableOrUnknown(
          data['not_installed']!,
          _notInstalledMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WatchedApp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchedApp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      watching: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}watching'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      removedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}removed_at'],
      ),
      notInstalled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}not_installed'],
      )!,
    );
  }

  @override
  $WatchedAppsTable createAlias(String alias) {
    return $WatchedAppsTable(attachedDatabase, alias);
  }
}

class WatchedApp extends DataClass implements Insertable<WatchedApp> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;
  final String packageName;
  final String label;
  final bool watching;
  final int addedAt;
  final int? removedAt;

  /// True when the package is absent on this device.
  ///
  /// A restored backup naming apps this phone does not have keeps the row,
  /// greyed, with its history intact. It must never fail the import.
  final bool notInstalled;
  const WatchedApp({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.packageName,
    required this.label,
    required this.watching,
    required this.addedAt,
    this.removedAt,
    required this.notInstalled,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['package_name'] = Variable<String>(packageName);
    map['label'] = Variable<String>(label);
    map['watching'] = Variable<bool>(watching);
    map['added_at'] = Variable<int>(addedAt);
    if (!nullToAbsent || removedAt != null) {
      map['removed_at'] = Variable<int>(removedAt);
    }
    map['not_installed'] = Variable<bool>(notInstalled);
    return map;
  }

  WatchedAppsCompanion toCompanion(bool nullToAbsent) {
    return WatchedAppsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      packageName: Value(packageName),
      label: Value(label),
      watching: Value(watching),
      addedAt: Value(addedAt),
      removedAt: removedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(removedAt),
      notInstalled: Value(notInstalled),
    );
  }

  factory WatchedApp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchedApp(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      packageName: serializer.fromJson<String>(json['packageName']),
      label: serializer.fromJson<String>(json['label']),
      watching: serializer.fromJson<bool>(json['watching']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      removedAt: serializer.fromJson<int?>(json['removedAt']),
      notInstalled: serializer.fromJson<bool>(json['notInstalled']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'packageName': serializer.toJson<String>(packageName),
      'label': serializer.toJson<String>(label),
      'watching': serializer.toJson<bool>(watching),
      'addedAt': serializer.toJson<int>(addedAt),
      'removedAt': serializer.toJson<int?>(removedAt),
      'notInstalled': serializer.toJson<bool>(notInstalled),
    };
  }

  WatchedApp copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? packageName,
    String? label,
    bool? watching,
    int? addedAt,
    Value<int?> removedAt = const Value.absent(),
    bool? notInstalled,
  }) => WatchedApp(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    packageName: packageName ?? this.packageName,
    label: label ?? this.label,
    watching: watching ?? this.watching,
    addedAt: addedAt ?? this.addedAt,
    removedAt: removedAt.present ? removedAt.value : this.removedAt,
    notInstalled: notInstalled ?? this.notInstalled,
  );
  WatchedApp copyWithCompanion(WatchedAppsCompanion data) {
    return WatchedApp(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      label: data.label.present ? data.label.value : this.label,
      watching: data.watching.present ? data.watching.value : this.watching,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      removedAt: data.removedAt.present ? data.removedAt.value : this.removedAt,
      notInstalled: data.notInstalled.present
          ? data.notInstalled.value
          : this.notInstalled,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchedApp(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('packageName: $packageName, ')
          ..write('label: $label, ')
          ..write('watching: $watching, ')
          ..write('addedAt: $addedAt, ')
          ..write('removedAt: $removedAt, ')
          ..write('notInstalled: $notInstalled')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    packageName,
    label,
    watching,
    addedAt,
    removedAt,
    notInstalled,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchedApp &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.packageName == this.packageName &&
          other.label == this.label &&
          other.watching == this.watching &&
          other.addedAt == this.addedAt &&
          other.removedAt == this.removedAt &&
          other.notInstalled == this.notInstalled);
}

class WatchedAppsCompanion extends UpdateCompanion<WatchedApp> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> packageName;
  final Value<String> label;
  final Value<bool> watching;
  final Value<int> addedAt;
  final Value<int?> removedAt;
  final Value<bool> notInstalled;
  final Value<int> rowid;
  const WatchedAppsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.packageName = const Value.absent(),
    this.label = const Value.absent(),
    this.watching = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.removedAt = const Value.absent(),
    this.notInstalled = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchedAppsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String packageName,
    required String label,
    this.watching = const Value.absent(),
    required int addedAt,
    this.removedAt = const Value.absent(),
    this.notInstalled = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       packageName = Value(packageName),
       label = Value(label),
       addedAt = Value(addedAt);
  static Insertable<WatchedApp> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? packageName,
    Expression<String>? label,
    Expression<bool>? watching,
    Expression<int>? addedAt,
    Expression<int>? removedAt,
    Expression<bool>? notInstalled,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (packageName != null) 'package_name': packageName,
      if (label != null) 'label': label,
      if (watching != null) 'watching': watching,
      if (addedAt != null) 'added_at': addedAt,
      if (removedAt != null) 'removed_at': removedAt,
      if (notInstalled != null) 'not_installed': notInstalled,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchedAppsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? packageName,
    Value<String>? label,
    Value<bool>? watching,
    Value<int>? addedAt,
    Value<int?>? removedAt,
    Value<bool>? notInstalled,
    Value<int>? rowid,
  }) {
    return WatchedAppsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      packageName: packageName ?? this.packageName,
      label: label ?? this.label,
      watching: watching ?? this.watching,
      addedAt: addedAt ?? this.addedAt,
      removedAt: removedAt ?? this.removedAt,
      notInstalled: notInstalled ?? this.notInstalled,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (watching.present) {
      map['watching'] = Variable<bool>(watching.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (removedAt.present) {
      map['removed_at'] = Variable<int>(removedAt.value);
    }
    if (notInstalled.present) {
      map['not_installed'] = Variable<bool>(notInstalled.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchedAppsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('packageName: $packageName, ')
          ..write('label: $label, ')
          ..write('watching: $watching, ')
          ..write('addedAt: $addedAt, ')
          ..write('removedAt: $removedAt, ')
          ..write('notInstalled: $notInstalled, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UsageCheckpointsTable extends UsageCheckpoints
    with TableInfo<$UsageCheckpointsTable, UsageCheckpoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsageCheckpointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _reconciledThroughMeta = const VerificationMeta(
    'reconciledThrough',
  );
  @override
  late final GeneratedColumn<int> reconciledThrough = GeneratedColumn<int>(
    'reconciled_through',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<int> recordedAt = GeneratedColumn<int>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, reconciledThrough, recordedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usage_checkpoints';
  @override
  VerificationContext validateIntegrity(
    Insertable<UsageCheckpoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('reconciled_through')) {
      context.handle(
        _reconciledThroughMeta,
        reconciledThrough.isAcceptableOrUnknown(
          data['reconciled_through']!,
          _reconciledThroughMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reconciledThroughMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UsageCheckpoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UsageCheckpoint(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      reconciledThrough: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reconciled_through'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_at'],
      )!,
    );
  }

  @override
  $UsageCheckpointsTable createAlias(String alias) {
    return $UsageCheckpointsTable(attachedDatabase, alias);
  }
}

class UsageCheckpoint extends DataClass implements Insertable<UsageCheckpoint> {
  final int id;
  final int reconciledThrough;
  final int recordedAt;
  const UsageCheckpoint({
    required this.id,
    required this.reconciledThrough,
    required this.recordedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['reconciled_through'] = Variable<int>(reconciledThrough);
    map['recorded_at'] = Variable<int>(recordedAt);
    return map;
  }

  UsageCheckpointsCompanion toCompanion(bool nullToAbsent) {
    return UsageCheckpointsCompanion(
      id: Value(id),
      reconciledThrough: Value(reconciledThrough),
      recordedAt: Value(recordedAt),
    );
  }

  factory UsageCheckpoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UsageCheckpoint(
      id: serializer.fromJson<int>(json['id']),
      reconciledThrough: serializer.fromJson<int>(json['reconciledThrough']),
      recordedAt: serializer.fromJson<int>(json['recordedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'reconciledThrough': serializer.toJson<int>(reconciledThrough),
      'recordedAt': serializer.toJson<int>(recordedAt),
    };
  }

  UsageCheckpoint copyWith({
    int? id,
    int? reconciledThrough,
    int? recordedAt,
  }) => UsageCheckpoint(
    id: id ?? this.id,
    reconciledThrough: reconciledThrough ?? this.reconciledThrough,
    recordedAt: recordedAt ?? this.recordedAt,
  );
  UsageCheckpoint copyWithCompanion(UsageCheckpointsCompanion data) {
    return UsageCheckpoint(
      id: data.id.present ? data.id.value : this.id,
      reconciledThrough: data.reconciledThrough.present
          ? data.reconciledThrough.value
          : this.reconciledThrough,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UsageCheckpoint(')
          ..write('id: $id, ')
          ..write('reconciledThrough: $reconciledThrough, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, reconciledThrough, recordedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UsageCheckpoint &&
          other.id == this.id &&
          other.reconciledThrough == this.reconciledThrough &&
          other.recordedAt == this.recordedAt);
}

class UsageCheckpointsCompanion extends UpdateCompanion<UsageCheckpoint> {
  final Value<int> id;
  final Value<int> reconciledThrough;
  final Value<int> recordedAt;
  const UsageCheckpointsCompanion({
    this.id = const Value.absent(),
    this.reconciledThrough = const Value.absent(),
    this.recordedAt = const Value.absent(),
  });
  UsageCheckpointsCompanion.insert({
    this.id = const Value.absent(),
    required int reconciledThrough,
    required int recordedAt,
  }) : reconciledThrough = Value(reconciledThrough),
       recordedAt = Value(recordedAt);
  static Insertable<UsageCheckpoint> custom({
    Expression<int>? id,
    Expression<int>? reconciledThrough,
    Expression<int>? recordedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (reconciledThrough != null) 'reconciled_through': reconciledThrough,
      if (recordedAt != null) 'recorded_at': recordedAt,
    });
  }

  UsageCheckpointsCompanion copyWith({
    Value<int>? id,
    Value<int>? reconciledThrough,
    Value<int>? recordedAt,
  }) {
    return UsageCheckpointsCompanion(
      id: id ?? this.id,
      reconciledThrough: reconciledThrough ?? this.reconciledThrough,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (reconciledThrough.present) {
      map['reconciled_through'] = Variable<int>(reconciledThrough.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<int>(recordedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsageCheckpointsCompanion(')
          ..write('id: $id, ')
          ..write('reconciledThrough: $reconciledThrough, ')
          ..write('recordedAt: $recordedAt')
          ..write(')'))
        .toString();
  }
}

class $DayLedgerTable extends DayLedger
    with TableInfo<$DayLedgerTable, DayLedgerData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DayLedgerTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _allowanceGrantedSecondsMeta =
      const VerificationMeta('allowanceGrantedSeconds');
  @override
  late final GeneratedColumn<int> allowanceGrantedSeconds =
      GeneratedColumn<int>(
        'allowance_granted_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _allowanceToDebtSecondsMeta =
      const VerificationMeta('allowanceToDebtSeconds');
  @override
  late final GeneratedColumn<int> allowanceToDebtSeconds = GeneratedColumn<int>(
    'allowance_to_debt_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _earnedSecondsMeta = const VerificationMeta(
    'earnedSeconds',
  );
  @override
  late final GeneratedColumn<int> earnedSeconds = GeneratedColumn<int>(
    'earned_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _earnCappedSecondsMeta = const VerificationMeta(
    'earnCappedSeconds',
  );
  @override
  late final GeneratedColumn<int> earnCappedSeconds = GeneratedColumn<int>(
    'earn_capped_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _spentSecondsMeta = const VerificationMeta(
    'spentSeconds',
  );
  @override
  late final GeneratedColumn<int> spentSeconds = GeneratedColumn<int>(
    'spent_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _graceUsedSecondsMeta = const VerificationMeta(
    'graceUsedSeconds',
  );
  @override
  late final GeneratedColumn<int> graceUsedSeconds = GeneratedColumn<int>(
    'grace_used_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unrepayableSecondsMeta =
      const VerificationMeta('unrepayableSeconds');
  @override
  late final GeneratedColumn<int> unrepayableSeconds = GeneratedColumn<int>(
    'unrepayable_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closingBalanceSecondsMeta =
      const VerificationMeta('closingBalanceSeconds');
  @override
  late final GeneratedColumn<int> closingBalanceSeconds = GeneratedColumn<int>(
    'closing_balance_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closingSavingsSecondsMeta =
      const VerificationMeta('closingSavingsSeconds');
  @override
  late final GeneratedColumn<int> closingSavingsSeconds = GeneratedColumn<int>(
    'closing_savings_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _overflowToSavingsSecondsMeta =
      const VerificationMeta('overflowToSavingsSeconds');
  @override
  late final GeneratedColumn<int> overflowToSavingsSeconds =
      GeneratedColumn<int>(
        'overflow_to_savings_seconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _treatedSecondsMeta = const VerificationMeta(
    'treatedSeconds',
  );
  @override
  late final GeneratedColumn<int> treatedSeconds = GeneratedColumn<int>(
    'treated_seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _solventMeta = const VerificationMeta(
    'solvent',
  );
  @override
  late final GeneratedColumn<bool> solvent = GeneratedColumn<bool>(
    'solvent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("solvent" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    allowanceGrantedSeconds,
    allowanceToDebtSeconds,
    earnedSeconds,
    earnCappedSeconds,
    spentSeconds,
    graceUsedSeconds,
    unrepayableSeconds,
    closingBalanceSeconds,
    closingSavingsSeconds,
    overflowToSavingsSeconds,
    treatedSeconds,
    solvent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_ledger';
  @override
  VerificationContext validateIntegrity(
    Insertable<DayLedgerData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('allowance_granted_seconds')) {
      context.handle(
        _allowanceGrantedSecondsMeta,
        allowanceGrantedSeconds.isAcceptableOrUnknown(
          data['allowance_granted_seconds']!,
          _allowanceGrantedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowanceGrantedSecondsMeta);
    }
    if (data.containsKey('allowance_to_debt_seconds')) {
      context.handle(
        _allowanceToDebtSecondsMeta,
        allowanceToDebtSeconds.isAcceptableOrUnknown(
          data['allowance_to_debt_seconds']!,
          _allowanceToDebtSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_allowanceToDebtSecondsMeta);
    }
    if (data.containsKey('earned_seconds')) {
      context.handle(
        _earnedSecondsMeta,
        earnedSeconds.isAcceptableOrUnknown(
          data['earned_seconds']!,
          _earnedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_earnedSecondsMeta);
    }
    if (data.containsKey('earn_capped_seconds')) {
      context.handle(
        _earnCappedSecondsMeta,
        earnCappedSeconds.isAcceptableOrUnknown(
          data['earn_capped_seconds']!,
          _earnCappedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_earnCappedSecondsMeta);
    }
    if (data.containsKey('spent_seconds')) {
      context.handle(
        _spentSecondsMeta,
        spentSeconds.isAcceptableOrUnknown(
          data['spent_seconds']!,
          _spentSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_spentSecondsMeta);
    }
    if (data.containsKey('grace_used_seconds')) {
      context.handle(
        _graceUsedSecondsMeta,
        graceUsedSeconds.isAcceptableOrUnknown(
          data['grace_used_seconds']!,
          _graceUsedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_graceUsedSecondsMeta);
    }
    if (data.containsKey('unrepayable_seconds')) {
      context.handle(
        _unrepayableSecondsMeta,
        unrepayableSeconds.isAcceptableOrUnknown(
          data['unrepayable_seconds']!,
          _unrepayableSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unrepayableSecondsMeta);
    }
    if (data.containsKey('closing_balance_seconds')) {
      context.handle(
        _closingBalanceSecondsMeta,
        closingBalanceSeconds.isAcceptableOrUnknown(
          data['closing_balance_seconds']!,
          _closingBalanceSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_closingBalanceSecondsMeta);
    }
    if (data.containsKey('closing_savings_seconds')) {
      context.handle(
        _closingSavingsSecondsMeta,
        closingSavingsSeconds.isAcceptableOrUnknown(
          data['closing_savings_seconds']!,
          _closingSavingsSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_closingSavingsSecondsMeta);
    }
    if (data.containsKey('overflow_to_savings_seconds')) {
      context.handle(
        _overflowToSavingsSecondsMeta,
        overflowToSavingsSeconds.isAcceptableOrUnknown(
          data['overflow_to_savings_seconds']!,
          _overflowToSavingsSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_overflowToSavingsSecondsMeta);
    }
    if (data.containsKey('treated_seconds')) {
      context.handle(
        _treatedSecondsMeta,
        treatedSeconds.isAcceptableOrUnknown(
          data['treated_seconds']!,
          _treatedSecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_treatedSecondsMeta);
    }
    if (data.containsKey('solvent')) {
      context.handle(
        _solventMeta,
        solvent.isAcceptableOrUnknown(data['solvent']!, _solventMeta),
      );
    } else if (isInserting) {
      context.missing(_solventMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DayLedgerData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DayLedgerData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      allowanceGrantedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}allowance_granted_seconds'],
      )!,
      allowanceToDebtSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}allowance_to_debt_seconds'],
      )!,
      earnedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}earned_seconds'],
      )!,
      earnCappedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}earn_capped_seconds'],
      )!,
      spentSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}spent_seconds'],
      )!,
      graceUsedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grace_used_seconds'],
      )!,
      unrepayableSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unrepayable_seconds'],
      )!,
      closingBalanceSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closing_balance_seconds'],
      )!,
      closingSavingsSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closing_savings_seconds'],
      )!,
      overflowToSavingsSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}overflow_to_savings_seconds'],
      )!,
      treatedSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}treated_seconds'],
      )!,
      solvent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}solvent'],
      )!,
    );
  }

  @override
  $DayLedgerTable createAlias(String alias) {
    return $DayLedgerTable(attachedDatabase, alias);
  }
}

class DayLedgerData extends DataClass implements Insertable<DayLedgerData> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;
  final int allowanceGrantedSeconds;
  final int allowanceToDebtSeconds;
  final int earnedSeconds;
  final int earnCappedSeconds;
  final int spentSeconds;
  final int graceUsedSeconds;
  final int unrepayableSeconds;
  final int closingBalanceSeconds;
  final int closingSavingsSeconds;
  final int overflowToSavingsSeconds;
  final int treatedSeconds;
  final bool solvent;
  const DayLedgerData({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    required this.allowanceGrantedSeconds,
    required this.allowanceToDebtSeconds,
    required this.earnedSeconds,
    required this.earnCappedSeconds,
    required this.spentSeconds,
    required this.graceUsedSeconds,
    required this.unrepayableSeconds,
    required this.closingBalanceSeconds,
    required this.closingSavingsSeconds,
    required this.overflowToSavingsSeconds,
    required this.treatedSeconds,
    required this.solvent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['allowance_granted_seconds'] = Variable<int>(allowanceGrantedSeconds);
    map['allowance_to_debt_seconds'] = Variable<int>(allowanceToDebtSeconds);
    map['earned_seconds'] = Variable<int>(earnedSeconds);
    map['earn_capped_seconds'] = Variable<int>(earnCappedSeconds);
    map['spent_seconds'] = Variable<int>(spentSeconds);
    map['grace_used_seconds'] = Variable<int>(graceUsedSeconds);
    map['unrepayable_seconds'] = Variable<int>(unrepayableSeconds);
    map['closing_balance_seconds'] = Variable<int>(closingBalanceSeconds);
    map['closing_savings_seconds'] = Variable<int>(closingSavingsSeconds);
    map['overflow_to_savings_seconds'] = Variable<int>(
      overflowToSavingsSeconds,
    );
    map['treated_seconds'] = Variable<int>(treatedSeconds);
    map['solvent'] = Variable<bool>(solvent);
    return map;
  }

  DayLedgerCompanion toCompanion(bool nullToAbsent) {
    return DayLedgerCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      allowanceGrantedSeconds: Value(allowanceGrantedSeconds),
      allowanceToDebtSeconds: Value(allowanceToDebtSeconds),
      earnedSeconds: Value(earnedSeconds),
      earnCappedSeconds: Value(earnCappedSeconds),
      spentSeconds: Value(spentSeconds),
      graceUsedSeconds: Value(graceUsedSeconds),
      unrepayableSeconds: Value(unrepayableSeconds),
      closingBalanceSeconds: Value(closingBalanceSeconds),
      closingSavingsSeconds: Value(closingSavingsSeconds),
      overflowToSavingsSeconds: Value(overflowToSavingsSeconds),
      treatedSeconds: Value(treatedSeconds),
      solvent: Value(solvent),
    );
  }

  factory DayLedgerData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DayLedgerData(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      allowanceGrantedSeconds: serializer.fromJson<int>(
        json['allowanceGrantedSeconds'],
      ),
      allowanceToDebtSeconds: serializer.fromJson<int>(
        json['allowanceToDebtSeconds'],
      ),
      earnedSeconds: serializer.fromJson<int>(json['earnedSeconds']),
      earnCappedSeconds: serializer.fromJson<int>(json['earnCappedSeconds']),
      spentSeconds: serializer.fromJson<int>(json['spentSeconds']),
      graceUsedSeconds: serializer.fromJson<int>(json['graceUsedSeconds']),
      unrepayableSeconds: serializer.fromJson<int>(json['unrepayableSeconds']),
      closingBalanceSeconds: serializer.fromJson<int>(
        json['closingBalanceSeconds'],
      ),
      closingSavingsSeconds: serializer.fromJson<int>(
        json['closingSavingsSeconds'],
      ),
      overflowToSavingsSeconds: serializer.fromJson<int>(
        json['overflowToSavingsSeconds'],
      ),
      treatedSeconds: serializer.fromJson<int>(json['treatedSeconds']),
      solvent: serializer.fromJson<bool>(json['solvent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'allowanceGrantedSeconds': serializer.toJson<int>(
        allowanceGrantedSeconds,
      ),
      'allowanceToDebtSeconds': serializer.toJson<int>(allowanceToDebtSeconds),
      'earnedSeconds': serializer.toJson<int>(earnedSeconds),
      'earnCappedSeconds': serializer.toJson<int>(earnCappedSeconds),
      'spentSeconds': serializer.toJson<int>(spentSeconds),
      'graceUsedSeconds': serializer.toJson<int>(graceUsedSeconds),
      'unrepayableSeconds': serializer.toJson<int>(unrepayableSeconds),
      'closingBalanceSeconds': serializer.toJson<int>(closingBalanceSeconds),
      'closingSavingsSeconds': serializer.toJson<int>(closingSavingsSeconds),
      'overflowToSavingsSeconds': serializer.toJson<int>(
        overflowToSavingsSeconds,
      ),
      'treatedSeconds': serializer.toJson<int>(treatedSeconds),
      'solvent': serializer.toJson<bool>(solvent),
    };
  }

  DayLedgerData copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    int? allowanceGrantedSeconds,
    int? allowanceToDebtSeconds,
    int? earnedSeconds,
    int? earnCappedSeconds,
    int? spentSeconds,
    int? graceUsedSeconds,
    int? unrepayableSeconds,
    int? closingBalanceSeconds,
    int? closingSavingsSeconds,
    int? overflowToSavingsSeconds,
    int? treatedSeconds,
    bool? solvent,
  }) => DayLedgerData(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    allowanceGrantedSeconds:
        allowanceGrantedSeconds ?? this.allowanceGrantedSeconds,
    allowanceToDebtSeconds:
        allowanceToDebtSeconds ?? this.allowanceToDebtSeconds,
    earnedSeconds: earnedSeconds ?? this.earnedSeconds,
    earnCappedSeconds: earnCappedSeconds ?? this.earnCappedSeconds,
    spentSeconds: spentSeconds ?? this.spentSeconds,
    graceUsedSeconds: graceUsedSeconds ?? this.graceUsedSeconds,
    unrepayableSeconds: unrepayableSeconds ?? this.unrepayableSeconds,
    closingBalanceSeconds: closingBalanceSeconds ?? this.closingBalanceSeconds,
    closingSavingsSeconds: closingSavingsSeconds ?? this.closingSavingsSeconds,
    overflowToSavingsSeconds:
        overflowToSavingsSeconds ?? this.overflowToSavingsSeconds,
    treatedSeconds: treatedSeconds ?? this.treatedSeconds,
    solvent: solvent ?? this.solvent,
  );
  DayLedgerData copyWithCompanion(DayLedgerCompanion data) {
    return DayLedgerData(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      allowanceGrantedSeconds: data.allowanceGrantedSeconds.present
          ? data.allowanceGrantedSeconds.value
          : this.allowanceGrantedSeconds,
      allowanceToDebtSeconds: data.allowanceToDebtSeconds.present
          ? data.allowanceToDebtSeconds.value
          : this.allowanceToDebtSeconds,
      earnedSeconds: data.earnedSeconds.present
          ? data.earnedSeconds.value
          : this.earnedSeconds,
      earnCappedSeconds: data.earnCappedSeconds.present
          ? data.earnCappedSeconds.value
          : this.earnCappedSeconds,
      spentSeconds: data.spentSeconds.present
          ? data.spentSeconds.value
          : this.spentSeconds,
      graceUsedSeconds: data.graceUsedSeconds.present
          ? data.graceUsedSeconds.value
          : this.graceUsedSeconds,
      unrepayableSeconds: data.unrepayableSeconds.present
          ? data.unrepayableSeconds.value
          : this.unrepayableSeconds,
      closingBalanceSeconds: data.closingBalanceSeconds.present
          ? data.closingBalanceSeconds.value
          : this.closingBalanceSeconds,
      closingSavingsSeconds: data.closingSavingsSeconds.present
          ? data.closingSavingsSeconds.value
          : this.closingSavingsSeconds,
      overflowToSavingsSeconds: data.overflowToSavingsSeconds.present
          ? data.overflowToSavingsSeconds.value
          : this.overflowToSavingsSeconds,
      treatedSeconds: data.treatedSeconds.present
          ? data.treatedSeconds.value
          : this.treatedSeconds,
      solvent: data.solvent.present ? data.solvent.value : this.solvent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DayLedgerData(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('allowanceGrantedSeconds: $allowanceGrantedSeconds, ')
          ..write('allowanceToDebtSeconds: $allowanceToDebtSeconds, ')
          ..write('earnedSeconds: $earnedSeconds, ')
          ..write('earnCappedSeconds: $earnCappedSeconds, ')
          ..write('spentSeconds: $spentSeconds, ')
          ..write('graceUsedSeconds: $graceUsedSeconds, ')
          ..write('unrepayableSeconds: $unrepayableSeconds, ')
          ..write('closingBalanceSeconds: $closingBalanceSeconds, ')
          ..write('closingSavingsSeconds: $closingSavingsSeconds, ')
          ..write('overflowToSavingsSeconds: $overflowToSavingsSeconds, ')
          ..write('treatedSeconds: $treatedSeconds, ')
          ..write('solvent: $solvent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    allowanceGrantedSeconds,
    allowanceToDebtSeconds,
    earnedSeconds,
    earnCappedSeconds,
    spentSeconds,
    graceUsedSeconds,
    unrepayableSeconds,
    closingBalanceSeconds,
    closingSavingsSeconds,
    overflowToSavingsSeconds,
    treatedSeconds,
    solvent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DayLedgerData &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.allowanceGrantedSeconds == this.allowanceGrantedSeconds &&
          other.allowanceToDebtSeconds == this.allowanceToDebtSeconds &&
          other.earnedSeconds == this.earnedSeconds &&
          other.earnCappedSeconds == this.earnCappedSeconds &&
          other.spentSeconds == this.spentSeconds &&
          other.graceUsedSeconds == this.graceUsedSeconds &&
          other.unrepayableSeconds == this.unrepayableSeconds &&
          other.closingBalanceSeconds == this.closingBalanceSeconds &&
          other.closingSavingsSeconds == this.closingSavingsSeconds &&
          other.overflowToSavingsSeconds == this.overflowToSavingsSeconds &&
          other.treatedSeconds == this.treatedSeconds &&
          other.solvent == this.solvent);
}

class DayLedgerCompanion extends UpdateCompanion<DayLedgerData> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<int> allowanceGrantedSeconds;
  final Value<int> allowanceToDebtSeconds;
  final Value<int> earnedSeconds;
  final Value<int> earnCappedSeconds;
  final Value<int> spentSeconds;
  final Value<int> graceUsedSeconds;
  final Value<int> unrepayableSeconds;
  final Value<int> closingBalanceSeconds;
  final Value<int> closingSavingsSeconds;
  final Value<int> overflowToSavingsSeconds;
  final Value<int> treatedSeconds;
  final Value<bool> solvent;
  final Value<int> rowid;
  const DayLedgerCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.allowanceGrantedSeconds = const Value.absent(),
    this.allowanceToDebtSeconds = const Value.absent(),
    this.earnedSeconds = const Value.absent(),
    this.earnCappedSeconds = const Value.absent(),
    this.spentSeconds = const Value.absent(),
    this.graceUsedSeconds = const Value.absent(),
    this.unrepayableSeconds = const Value.absent(),
    this.closingBalanceSeconds = const Value.absent(),
    this.closingSavingsSeconds = const Value.absent(),
    this.overflowToSavingsSeconds = const Value.absent(),
    this.treatedSeconds = const Value.absent(),
    this.solvent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DayLedgerCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    required int allowanceGrantedSeconds,
    required int allowanceToDebtSeconds,
    required int earnedSeconds,
    required int earnCappedSeconds,
    required int spentSeconds,
    required int graceUsedSeconds,
    required int unrepayableSeconds,
    required int closingBalanceSeconds,
    required int closingSavingsSeconds,
    required int overflowToSavingsSeconds,
    required int treatedSeconds,
    required bool solvent,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       allowanceGrantedSeconds = Value(allowanceGrantedSeconds),
       allowanceToDebtSeconds = Value(allowanceToDebtSeconds),
       earnedSeconds = Value(earnedSeconds),
       earnCappedSeconds = Value(earnCappedSeconds),
       spentSeconds = Value(spentSeconds),
       graceUsedSeconds = Value(graceUsedSeconds),
       unrepayableSeconds = Value(unrepayableSeconds),
       closingBalanceSeconds = Value(closingBalanceSeconds),
       closingSavingsSeconds = Value(closingSavingsSeconds),
       overflowToSavingsSeconds = Value(overflowToSavingsSeconds),
       treatedSeconds = Value(treatedSeconds),
       solvent = Value(solvent);
  static Insertable<DayLedgerData> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<int>? allowanceGrantedSeconds,
    Expression<int>? allowanceToDebtSeconds,
    Expression<int>? earnedSeconds,
    Expression<int>? earnCappedSeconds,
    Expression<int>? spentSeconds,
    Expression<int>? graceUsedSeconds,
    Expression<int>? unrepayableSeconds,
    Expression<int>? closingBalanceSeconds,
    Expression<int>? closingSavingsSeconds,
    Expression<int>? overflowToSavingsSeconds,
    Expression<int>? treatedSeconds,
    Expression<bool>? solvent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (allowanceGrantedSeconds != null)
        'allowance_granted_seconds': allowanceGrantedSeconds,
      if (allowanceToDebtSeconds != null)
        'allowance_to_debt_seconds': allowanceToDebtSeconds,
      if (earnedSeconds != null) 'earned_seconds': earnedSeconds,
      if (earnCappedSeconds != null) 'earn_capped_seconds': earnCappedSeconds,
      if (spentSeconds != null) 'spent_seconds': spentSeconds,
      if (graceUsedSeconds != null) 'grace_used_seconds': graceUsedSeconds,
      if (unrepayableSeconds != null) 'unrepayable_seconds': unrepayableSeconds,
      if (closingBalanceSeconds != null)
        'closing_balance_seconds': closingBalanceSeconds,
      if (closingSavingsSeconds != null)
        'closing_savings_seconds': closingSavingsSeconds,
      if (overflowToSavingsSeconds != null)
        'overflow_to_savings_seconds': overflowToSavingsSeconds,
      if (treatedSeconds != null) 'treated_seconds': treatedSeconds,
      if (solvent != null) 'solvent': solvent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DayLedgerCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<int>? allowanceGrantedSeconds,
    Value<int>? allowanceToDebtSeconds,
    Value<int>? earnedSeconds,
    Value<int>? earnCappedSeconds,
    Value<int>? spentSeconds,
    Value<int>? graceUsedSeconds,
    Value<int>? unrepayableSeconds,
    Value<int>? closingBalanceSeconds,
    Value<int>? closingSavingsSeconds,
    Value<int>? overflowToSavingsSeconds,
    Value<int>? treatedSeconds,
    Value<bool>? solvent,
    Value<int>? rowid,
  }) {
    return DayLedgerCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      allowanceGrantedSeconds:
          allowanceGrantedSeconds ?? this.allowanceGrantedSeconds,
      allowanceToDebtSeconds:
          allowanceToDebtSeconds ?? this.allowanceToDebtSeconds,
      earnedSeconds: earnedSeconds ?? this.earnedSeconds,
      earnCappedSeconds: earnCappedSeconds ?? this.earnCappedSeconds,
      spentSeconds: spentSeconds ?? this.spentSeconds,
      graceUsedSeconds: graceUsedSeconds ?? this.graceUsedSeconds,
      unrepayableSeconds: unrepayableSeconds ?? this.unrepayableSeconds,
      closingBalanceSeconds:
          closingBalanceSeconds ?? this.closingBalanceSeconds,
      closingSavingsSeconds:
          closingSavingsSeconds ?? this.closingSavingsSeconds,
      overflowToSavingsSeconds:
          overflowToSavingsSeconds ?? this.overflowToSavingsSeconds,
      treatedSeconds: treatedSeconds ?? this.treatedSeconds,
      solvent: solvent ?? this.solvent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (allowanceGrantedSeconds.present) {
      map['allowance_granted_seconds'] = Variable<int>(
        allowanceGrantedSeconds.value,
      );
    }
    if (allowanceToDebtSeconds.present) {
      map['allowance_to_debt_seconds'] = Variable<int>(
        allowanceToDebtSeconds.value,
      );
    }
    if (earnedSeconds.present) {
      map['earned_seconds'] = Variable<int>(earnedSeconds.value);
    }
    if (earnCappedSeconds.present) {
      map['earn_capped_seconds'] = Variable<int>(earnCappedSeconds.value);
    }
    if (spentSeconds.present) {
      map['spent_seconds'] = Variable<int>(spentSeconds.value);
    }
    if (graceUsedSeconds.present) {
      map['grace_used_seconds'] = Variable<int>(graceUsedSeconds.value);
    }
    if (unrepayableSeconds.present) {
      map['unrepayable_seconds'] = Variable<int>(unrepayableSeconds.value);
    }
    if (closingBalanceSeconds.present) {
      map['closing_balance_seconds'] = Variable<int>(
        closingBalanceSeconds.value,
      );
    }
    if (closingSavingsSeconds.present) {
      map['closing_savings_seconds'] = Variable<int>(
        closingSavingsSeconds.value,
      );
    }
    if (overflowToSavingsSeconds.present) {
      map['overflow_to_savings_seconds'] = Variable<int>(
        overflowToSavingsSeconds.value,
      );
    }
    if (treatedSeconds.present) {
      map['treated_seconds'] = Variable<int>(treatedSeconds.value);
    }
    if (solvent.present) {
      map['solvent'] = Variable<bool>(solvent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DayLedgerCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('allowanceGrantedSeconds: $allowanceGrantedSeconds, ')
          ..write('allowanceToDebtSeconds: $allowanceToDebtSeconds, ')
          ..write('earnedSeconds: $earnedSeconds, ')
          ..write('earnCappedSeconds: $earnCappedSeconds, ')
          ..write('spentSeconds: $spentSeconds, ')
          ..write('graceUsedSeconds: $graceUsedSeconds, ')
          ..write('unrepayableSeconds: $unrepayableSeconds, ')
          ..write('closingBalanceSeconds: $closingBalanceSeconds, ')
          ..write('closingSavingsSeconds: $closingSavingsSeconds, ')
          ..write('overflowToSavingsSeconds: $overflowToSavingsSeconds, ')
          ..write('treatedSeconds: $treatedSeconds, ')
          ..write('solvent: $solvent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DaySpendTable extends DaySpend
    with TableInfo<$DaySpendTable, DaySpendData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DaySpendTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _packageNameMeta = const VerificationMeta(
    'packageName',
  );
  @override
  late final GeneratedColumn<String> packageName = GeneratedColumn<String>(
    'package_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    packageName,
    seconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'day_spend';
  @override
  VerificationContext validateIntegrity(
    Insertable<DaySpendData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('package_name')) {
      context.handle(
        _packageNameMeta,
        packageName.isAcceptableOrUnknown(
          data['package_name']!,
          _packageNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_packageNameMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DaySpendData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DaySpendData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      packageName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}package_name'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
    );
  }

  @override
  $DaySpendTable createAlias(String alias) {
    return $DaySpendTable(attachedDatabase, alias);
  }
}

class DaySpendData extends DataClass implements Insertable<DaySpendData> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;
  final String packageName;
  final int seconds;
  const DaySpendData({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    required this.packageName,
    required this.seconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['package_name'] = Variable<String>(packageName);
    map['seconds'] = Variable<int>(seconds);
    return map;
  }

  DaySpendCompanion toCompanion(bool nullToAbsent) {
    return DaySpendCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      packageName: Value(packageName),
      seconds: Value(seconds),
    );
  }

  factory DaySpendData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DaySpendData(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      packageName: serializer.fromJson<String>(json['packageName']),
      seconds: serializer.fromJson<int>(json['seconds']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'packageName': serializer.toJson<String>(packageName),
      'seconds': serializer.toJson<int>(seconds),
    };
  }

  DaySpendData copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    String? packageName,
    int? seconds,
  }) => DaySpendData(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    packageName: packageName ?? this.packageName,
    seconds: seconds ?? this.seconds,
  );
  DaySpendData copyWithCompanion(DaySpendCompanion data) {
    return DaySpendData(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      packageName: data.packageName.present
          ? data.packageName.value
          : this.packageName,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DaySpendData(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('packageName: $packageName, ')
          ..write('seconds: $seconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    packageName,
    seconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DaySpendData &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.packageName == this.packageName &&
          other.seconds == this.seconds);
}

class DaySpendCompanion extends UpdateCompanion<DaySpendData> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<String> packageName;
  final Value<int> seconds;
  final Value<int> rowid;
  const DaySpendCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.packageName = const Value.absent(),
    this.seconds = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DaySpendCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    required String packageName,
    required int seconds,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       packageName = Value(packageName),
       seconds = Value(seconds);
  static Insertable<DaySpendData> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<String>? packageName,
    Expression<int>? seconds,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (packageName != null) 'package_name': packageName,
      if (seconds != null) 'seconds': seconds,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DaySpendCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<String>? packageName,
    Value<int>? seconds,
    Value<int>? rowid,
  }) {
    return DaySpendCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      packageName: packageName ?? this.packageName,
      seconds: seconds ?? this.seconds,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (packageName.present) {
      map['package_name'] = Variable<String>(packageName.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DaySpendCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('packageName: $packageName, ')
          ..write('seconds: $seconds, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TreatsTable extends Treats with TableInfo<$TreatsTable, Treat> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TreatsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minutesBurnedMeta = const VerificationMeta(
    'minutesBurned',
  );
  @override
  late final GeneratedColumn<int> minutesBurned = GeneratedColumn<int>(
    'minutes_burned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    minutesBurned,
    label,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'treats';
  @override
  VerificationContext validateIntegrity(
    Insertable<Treat> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('minutes_burned')) {
      context.handle(
        _minutesBurnedMeta,
        minutesBurned.isAcceptableOrUnknown(
          data['minutes_burned']!,
          _minutesBurnedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_minutesBurnedMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Treat map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Treat(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      minutesBurned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes_burned'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TreatsTable createAlias(String alias) {
    return $TreatsTable(attachedDatabase, alias);
  }
}

class Treat extends DataClass implements Insertable<Treat> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;
  final int minutesBurned;
  final String label;
  final String? note;
  const Treat({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    required this.minutesBurned,
    required this.label,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['minutes_burned'] = Variable<int>(minutesBurned);
    map['label'] = Variable<String>(label);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TreatsCompanion toCompanion(bool nullToAbsent) {
    return TreatsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      minutesBurned: Value(minutesBurned),
      label: Value(label),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Treat.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Treat(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      minutesBurned: serializer.fromJson<int>(json['minutesBurned']),
      label: serializer.fromJson<String>(json['label']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'minutesBurned': serializer.toJson<int>(minutesBurned),
      'label': serializer.toJson<String>(label),
      'note': serializer.toJson<String?>(note),
    };
  }

  Treat copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    int? minutesBurned,
    String? label,
    Value<String?> note = const Value.absent(),
  }) => Treat(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    minutesBurned: minutesBurned ?? this.minutesBurned,
    label: label ?? this.label,
    note: note.present ? note.value : this.note,
  );
  Treat copyWithCompanion(TreatsCompanion data) {
    return Treat(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      minutesBurned: data.minutesBurned.present
          ? data.minutesBurned.value
          : this.minutesBurned,
      label: data.label.present ? data.label.value : this.label,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Treat(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('minutesBurned: $minutesBurned, ')
          ..write('label: $label, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    minutesBurned,
    label,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Treat &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.minutesBurned == this.minutesBurned &&
          other.label == this.label &&
          other.note == this.note);
}

class TreatsCompanion extends UpdateCompanion<Treat> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<int> minutesBurned;
  final Value<String> label;
  final Value<String?> note;
  final Value<int> rowid;
  const TreatsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.minutesBurned = const Value.absent(),
    this.label = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TreatsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    required int minutesBurned,
    required String label,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       minutesBurned = Value(minutesBurned),
       label = Value(label);
  static Insertable<Treat> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<int>? minutesBurned,
    Expression<String>? label,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (minutesBurned != null) 'minutes_burned': minutesBurned,
      if (label != null) 'label': label,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TreatsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<int>? minutesBurned,
    Value<String>? label,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return TreatsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      minutesBurned: minutesBurned ?? this.minutesBurned,
      label: label ?? this.label,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (minutesBurned.present) {
      map['minutes_burned'] = Variable<int>(minutesBurned.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TreatsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('minutesBurned: $minutesBurned, ')
          ..write('label: $label, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SavingsTransfersTable extends SavingsTransfers
    with TableInfo<$SavingsTransfersTable, SavingsTransfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SavingsTransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondsMeta = const VerificationMeta(
    'seconds',
  );
  @override
  late final GeneratedColumn<int> seconds = GeneratedColumn<int>(
    'seconds',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toSavingsMeta = const VerificationMeta(
    'toSavings',
  );
  @override
  late final GeneratedColumn<bool> toSavings = GeneratedColumn<bool>(
    'to_savings',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("to_savings" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    seconds,
    toSavings,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'savings_transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SavingsTransfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('seconds')) {
      context.handle(
        _secondsMeta,
        seconds.isAcceptableOrUnknown(data['seconds']!, _secondsMeta),
      );
    } else if (isInserting) {
      context.missing(_secondsMeta);
    }
    if (data.containsKey('to_savings')) {
      context.handle(
        _toSavingsMeta,
        toSavings.isAcceptableOrUnknown(data['to_savings']!, _toSavingsMeta),
      );
    } else if (isInserting) {
      context.missing(_toSavingsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SavingsTransfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SavingsTransfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      seconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seconds'],
      )!,
      toSavings: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}to_savings'],
      )!,
    );
  }

  @override
  $SavingsTransfersTable createAlias(String alias) {
    return $SavingsTransfersTable(attachedDatabase, alias);
  }
}

class SavingsTransfer extends DataClass implements Insertable<SavingsTransfer> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;
  final int seconds;

  /// True moves balance into savings; false is a logged withdrawal covering a
  /// debt. There is no automatic bailout.
  final bool toSavings;
  const SavingsTransfer({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    required this.seconds,
    required this.toSavings,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['seconds'] = Variable<int>(seconds);
    map['to_savings'] = Variable<bool>(toSavings);
    return map;
  }

  SavingsTransfersCompanion toCompanion(bool nullToAbsent) {
    return SavingsTransfersCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      seconds: Value(seconds),
      toSavings: Value(toSavings),
    );
  }

  factory SavingsTransfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SavingsTransfer(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      seconds: serializer.fromJson<int>(json['seconds']),
      toSavings: serializer.fromJson<bool>(json['toSavings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'seconds': serializer.toJson<int>(seconds),
      'toSavings': serializer.toJson<bool>(toSavings),
    };
  }

  SavingsTransfer copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    int? seconds,
    bool? toSavings,
  }) => SavingsTransfer(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    seconds: seconds ?? this.seconds,
    toSavings: toSavings ?? this.toSavings,
  );
  SavingsTransfer copyWithCompanion(SavingsTransfersCompanion data) {
    return SavingsTransfer(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      seconds: data.seconds.present ? data.seconds.value : this.seconds,
      toSavings: data.toSavings.present ? data.toSavings.value : this.toSavings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SavingsTransfer(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('seconds: $seconds, ')
          ..write('toSavings: $toSavings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    seconds,
    toSavings,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SavingsTransfer &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.seconds == this.seconds &&
          other.toSavings == this.toSavings);
}

class SavingsTransfersCompanion extends UpdateCompanion<SavingsTransfer> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<int> seconds;
  final Value<bool> toSavings;
  final Value<int> rowid;
  const SavingsTransfersCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.seconds = const Value.absent(),
    this.toSavings = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SavingsTransfersCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    required int seconds,
    required bool toSavings,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       seconds = Value(seconds),
       toSavings = Value(toSavings);
  static Insertable<SavingsTransfer> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<int>? seconds,
    Expression<bool>? toSavings,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (seconds != null) 'seconds': seconds,
      if (toSavings != null) 'to_savings': toSavings,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SavingsTransfersCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<int>? seconds,
    Value<bool>? toSavings,
    Value<int>? rowid,
  }) {
    return SavingsTransfersCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      seconds: seconds ?? this.seconds,
      toSavings: toSavings ?? this.toSavings,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (seconds.present) {
      map['seconds'] = Variable<int>(seconds.value);
    }
    if (toSavings.present) {
      map['to_savings'] = Variable<bool>(toSavings.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SavingsTransfersCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('seconds: $seconds, ')
          ..write('toSavings: $toSavings, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StickerStampsTable extends StickerStamps
    with TableInfo<$StickerStampsTable, StickerStamp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StickerStampsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stickerIdMeta = const VerificationMeta(
    'stickerId',
  );
  @override
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
    'sticker_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stampedAtMeta = const VerificationMeta(
    'stampedAt',
  );
  @override
  late final GeneratedColumn<int> stampedAt = GeneratedColumn<int>(
    'stamped_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    stickerId,
    taskId,
    stampedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sticker_stamps';
  @override
  VerificationContext validateIntegrity(
    Insertable<StickerStamp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('sticker_id')) {
      context.handle(
        _stickerIdMeta,
        stickerId.isAcceptableOrUnknown(data['sticker_id']!, _stickerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_stickerIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('stamped_at')) {
      context.handle(
        _stampedAtMeta,
        stampedAt.isAcceptableOrUnknown(data['stamped_at']!, _stampedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_stampedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StickerStamp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StickerStamp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      stickerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sticker_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      stampedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stamped_at'],
      )!,
    );
  }

  @override
  $StickerStampsTable createAlias(String alias) {
    return $StickerStampsTable(attachedDatabase, alias);
  }
}

class StickerStamp extends DataClass implements Insertable<StickerStamp> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;
  final String stickerId;
  final String taskId;
  final int stampedAt;
  const StickerStamp({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    required this.stickerId,
    required this.taskId,
    required this.stampedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['sticker_id'] = Variable<String>(stickerId);
    map['task_id'] = Variable<String>(taskId);
    map['stamped_at'] = Variable<int>(stampedAt);
    return map;
  }

  StickerStampsCompanion toCompanion(bool nullToAbsent) {
    return StickerStampsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      stickerId: Value(stickerId),
      taskId: Value(taskId),
      stampedAt: Value(stampedAt),
    );
  }

  factory StickerStamp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StickerStamp(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      stickerId: serializer.fromJson<String>(json['stickerId']),
      taskId: serializer.fromJson<String>(json['taskId']),
      stampedAt: serializer.fromJson<int>(json['stampedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'stickerId': serializer.toJson<String>(stickerId),
      'taskId': serializer.toJson<String>(taskId),
      'stampedAt': serializer.toJson<int>(stampedAt),
    };
  }

  StickerStamp copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    String? stickerId,
    String? taskId,
    int? stampedAt,
  }) => StickerStamp(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    stickerId: stickerId ?? this.stickerId,
    taskId: taskId ?? this.taskId,
    stampedAt: stampedAt ?? this.stampedAt,
  );
  StickerStamp copyWithCompanion(StickerStampsCompanion data) {
    return StickerStamp(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      stickerId: data.stickerId.present ? data.stickerId.value : this.stickerId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      stampedAt: data.stampedAt.present ? data.stampedAt.value : this.stampedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StickerStamp(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('stickerId: $stickerId, ')
          ..write('taskId: $taskId, ')
          ..write('stampedAt: $stampedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    stickerId,
    taskId,
    stampedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StickerStamp &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.stickerId == this.stickerId &&
          other.taskId == this.taskId &&
          other.stampedAt == this.stampedAt);
}

class StickerStampsCompanion extends UpdateCompanion<StickerStamp> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<String> stickerId;
  final Value<String> taskId;
  final Value<int> stampedAt;
  final Value<int> rowid;
  const StickerStampsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.stampedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StickerStampsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    required String stickerId,
    required String taskId,
    required int stampedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       stickerId = Value(stickerId),
       taskId = Value(taskId),
       stampedAt = Value(stampedAt);
  static Insertable<StickerStamp> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<String>? stickerId,
    Expression<String>? taskId,
    Expression<int>? stampedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (stickerId != null) 'sticker_id': stickerId,
      if (taskId != null) 'task_id': taskId,
      if (stampedAt != null) 'stamped_at': stampedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StickerStampsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<String>? stickerId,
    Value<String>? taskId,
    Value<int>? stampedAt,
    Value<int>? rowid,
  }) {
    return StickerStampsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      stickerId: stickerId ?? this.stickerId,
      taskId: taskId ?? this.taskId,
      stampedAt: stampedAt ?? this.stampedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (stampedAt.present) {
      map['stamped_at'] = Variable<int>(stampedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StickerStampsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('stickerId: $stickerId, ')
          ..write('taskId: $taskId, ')
          ..write('stampedAt: $stampedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 200,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stickerIdMeta = const VerificationMeta(
    'stickerId',
  );
  @override
  late final GeneratedColumn<String> stickerId = GeneratedColumn<String>(
    'sticker_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedProjectIdMeta = const VerificationMeta(
    'linkedProjectId',
  );
  @override
  late final GeneratedColumn<String> linkedProjectId = GeneratedColumn<String>(
    'linked_project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _achievedAtMeta = const VerificationMeta(
    'achievedAt',
  );
  @override
  late final GeneratedColumn<int> achievedAt = GeneratedColumn<int>(
    'achieved_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    scope,
    title,
    note,
    stickerId,
    linkedProjectId,
    createdAt,
    achievedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(
        _scopeMeta,
        scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta),
      );
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sticker_id')) {
      context.handle(
        _stickerIdMeta,
        stickerId.isAcceptableOrUnknown(data['sticker_id']!, _stickerIdMeta),
      );
    }
    if (data.containsKey('linked_project_id')) {
      context.handle(
        _linkedProjectIdMeta,
        linkedProjectId.isAcceptableOrUnknown(
          data['linked_project_id']!,
          _linkedProjectIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('achieved_at')) {
      context.handle(
        _achievedAtMeta,
        achievedAt.isAcceptableOrUnknown(data['achieved_at']!, _achievedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      scope: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scope'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      stickerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sticker_id'],
      ),
      linkedProjectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_project_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      achievedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}achieved_at'],
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `year` or `life`.
  final String scope;
  final String title;
  final String? note;
  final String? stickerId;
  final String? linkedProjectId;
  final int createdAt;
  final int? achievedAt;
  const Goal({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.scope,
    required this.title,
    this.note,
    this.stickerId,
    this.linkedProjectId,
    required this.createdAt,
    this.achievedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['scope'] = Variable<String>(scope);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || stickerId != null) {
      map['sticker_id'] = Variable<String>(stickerId);
    }
    if (!nullToAbsent || linkedProjectId != null) {
      map['linked_project_id'] = Variable<String>(linkedProjectId);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || achievedAt != null) {
      map['achieved_at'] = Variable<int>(achievedAt);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      scope: Value(scope),
      title: Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      stickerId: stickerId == null && nullToAbsent
          ? const Value.absent()
          : Value(stickerId),
      linkedProjectId: linkedProjectId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedProjectId),
      createdAt: Value(createdAt),
      achievedAt: achievedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(achievedAt),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      scope: serializer.fromJson<String>(json['scope']),
      title: serializer.fromJson<String>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      stickerId: serializer.fromJson<String?>(json['stickerId']),
      linkedProjectId: serializer.fromJson<String?>(json['linkedProjectId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      achievedAt: serializer.fromJson<int?>(json['achievedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'scope': serializer.toJson<String>(scope),
      'title': serializer.toJson<String>(title),
      'note': serializer.toJson<String?>(note),
      'stickerId': serializer.toJson<String?>(stickerId),
      'linkedProjectId': serializer.toJson<String?>(linkedProjectId),
      'createdAt': serializer.toJson<int>(createdAt),
      'achievedAt': serializer.toJson<int?>(achievedAt),
    };
  }

  Goal copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? scope,
    String? title,
    Value<String?> note = const Value.absent(),
    Value<String?> stickerId = const Value.absent(),
    Value<String?> linkedProjectId = const Value.absent(),
    int? createdAt,
    Value<int?> achievedAt = const Value.absent(),
  }) => Goal(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    scope: scope ?? this.scope,
    title: title ?? this.title,
    note: note.present ? note.value : this.note,
    stickerId: stickerId.present ? stickerId.value : this.stickerId,
    linkedProjectId: linkedProjectId.present
        ? linkedProjectId.value
        : this.linkedProjectId,
    createdAt: createdAt ?? this.createdAt,
    achievedAt: achievedAt.present ? achievedAt.value : this.achievedAt,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      scope: data.scope.present ? data.scope.value : this.scope,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      stickerId: data.stickerId.present ? data.stickerId.value : this.stickerId,
      linkedProjectId: data.linkedProjectId.present
          ? data.linkedProjectId.value
          : this.linkedProjectId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      achievedAt: data.achievedAt.present
          ? data.achievedAt.value
          : this.achievedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('scope: $scope, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('stickerId: $stickerId, ')
          ..write('linkedProjectId: $linkedProjectId, ')
          ..write('createdAt: $createdAt, ')
          ..write('achievedAt: $achievedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    scope,
    title,
    note,
    stickerId,
    linkedProjectId,
    createdAt,
    achievedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.scope == this.scope &&
          other.title == this.title &&
          other.note == this.note &&
          other.stickerId == this.stickerId &&
          other.linkedProjectId == this.linkedProjectId &&
          other.createdAt == this.createdAt &&
          other.achievedAt == this.achievedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> scope;
  final Value<String> title;
  final Value<String?> note;
  final Value<String?> stickerId;
  final Value<String?> linkedProjectId;
  final Value<int> createdAt;
  final Value<int?> achievedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.scope = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.linkedProjectId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.achievedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String scope,
    required String title,
    this.note = const Value.absent(),
    this.stickerId = const Value.absent(),
    this.linkedProjectId = const Value.absent(),
    required int createdAt,
    this.achievedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       scope = Value(scope),
       title = Value(title),
       createdAt = Value(createdAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? scope,
    Expression<String>? title,
    Expression<String>? note,
    Expression<String>? stickerId,
    Expression<String>? linkedProjectId,
    Expression<int>? createdAt,
    Expression<int>? achievedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (scope != null) 'scope': scope,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (stickerId != null) 'sticker_id': stickerId,
      if (linkedProjectId != null) 'linked_project_id': linkedProjectId,
      if (createdAt != null) 'created_at': createdAt,
      if (achievedAt != null) 'achieved_at': achievedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? scope,
    Value<String>? title,
    Value<String?>? note,
    Value<String?>? stickerId,
    Value<String?>? linkedProjectId,
    Value<int>? createdAt,
    Value<int?>? achievedAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      scope: scope ?? this.scope,
      title: title ?? this.title,
      note: note ?? this.note,
      stickerId: stickerId ?? this.stickerId,
      linkedProjectId: linkedProjectId ?? this.linkedProjectId,
      createdAt: createdAt ?? this.createdAt,
      achievedAt: achievedAt ?? this.achievedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (stickerId.present) {
      map['sticker_id'] = Variable<String>(stickerId.value);
    }
    if (linkedProjectId.present) {
      map['linked_project_id'] = Variable<String>(linkedProjectId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (achievedAt.present) {
      map['achieved_at'] = Variable<int>(achievedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('scope: $scope, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('stickerId: $stickerId, ')
          ..write('linkedProjectId: $linkedProjectId, ')
          ..write('createdAt: $createdAt, ')
          ..write('achievedAt: $achievedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SuggestionHistoryTable extends SuggestionHistory
    with TableInfo<$SuggestionHistoryTable, SuggestionHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SuggestionHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayKeyMeta = const VerificationMeta('dayKey');
  @override
  late final GeneratedColumn<String> dayKey = GeneratedColumn<String>(
    'day_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  @override
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    itemId,
    outcome,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'suggestion_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SuggestionHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('day_key')) {
      context.handle(
        _dayKeyMeta,
        dayKey.isAcceptableOrUnknown(data['day_key']!, _dayKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dayKeyMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SuggestionHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SuggestionHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      dayKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_key'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
    );
  }

  @override
  $SuggestionHistoryTable createAlias(String alias) {
    return $SuggestionHistoryTable(attachedDatabase, alias);
  }
}

class SuggestionHistoryData extends DataClass
    implements Insertable<SuggestionHistoryData> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// `YYYY-MM-DD`, computed once by the app's own day-boundary rule.
  final String dayKey;

  /// Device offset from UTC when the row was written, in minutes.
  ///
  /// Kept so a statement can explain itself later, and so a merge can tell a
  /// genuine duplicate from two rows written in different zones.
  final int tzOffsetMinutes;
  final String itemId;

  /// `offered` / `accepted` / `dismissed`.
  final String outcome;
  const SuggestionHistoryData({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.dayKey,
    required this.tzOffsetMinutes,
    required this.itemId,
    required this.outcome,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['day_key'] = Variable<String>(dayKey);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['item_id'] = Variable<String>(itemId);
    map['outcome'] = Variable<String>(outcome);
    return map;
  }

  SuggestionHistoryCompanion toCompanion(bool nullToAbsent) {
    return SuggestionHistoryCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      dayKey: Value(dayKey),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      itemId: Value(itemId),
      outcome: Value(outcome),
    );
  }

  factory SuggestionHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SuggestionHistoryData(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      dayKey: serializer.fromJson<String>(json['dayKey']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      itemId: serializer.fromJson<String>(json['itemId']),
      outcome: serializer.fromJson<String>(json['outcome']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'dayKey': serializer.toJson<String>(dayKey),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'itemId': serializer.toJson<String>(itemId),
      'outcome': serializer.toJson<String>(outcome),
    };
  }

  SuggestionHistoryData copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? dayKey,
    int? tzOffsetMinutes,
    String? itemId,
    String? outcome,
  }) => SuggestionHistoryData(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    dayKey: dayKey ?? this.dayKey,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    itemId: itemId ?? this.itemId,
    outcome: outcome ?? this.outcome,
  );
  SuggestionHistoryData copyWithCompanion(SuggestionHistoryCompanion data) {
    return SuggestionHistoryData(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      dayKey: data.dayKey.present ? data.dayKey.value : this.dayKey,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SuggestionHistoryData(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('itemId: $itemId, ')
          ..write('outcome: $outcome')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    dayKey,
    tzOffsetMinutes,
    itemId,
    outcome,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuggestionHistoryData &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.dayKey == this.dayKey &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.itemId == this.itemId &&
          other.outcome == this.outcome);
}

class SuggestionHistoryCompanion
    extends UpdateCompanion<SuggestionHistoryData> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> dayKey;
  final Value<int> tzOffsetMinutes;
  final Value<String> itemId;
  final Value<String> outcome;
  final Value<int> rowid;
  const SuggestionHistoryCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.dayKey = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.itemId = const Value.absent(),
    this.outcome = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SuggestionHistoryCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String dayKey,
    required int tzOffsetMinutes,
    required String itemId,
    required String outcome,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       dayKey = Value(dayKey),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       itemId = Value(itemId),
       outcome = Value(outcome);
  static Insertable<SuggestionHistoryData> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? dayKey,
    Expression<int>? tzOffsetMinutes,
    Expression<String>? itemId,
    Expression<String>? outcome,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (dayKey != null) 'day_key': dayKey,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (itemId != null) 'item_id': itemId,
      if (outcome != null) 'outcome': outcome,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SuggestionHistoryCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? dayKey,
    Value<int>? tzOffsetMinutes,
    Value<String>? itemId,
    Value<String>? outcome,
    Value<int>? rowid,
  }) {
    return SuggestionHistoryCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      dayKey: dayKey ?? this.dayKey,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      itemId: itemId ?? this.itemId,
      outcome: outcome ?? this.outcome,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (dayKey.present) {
      map['day_key'] = Variable<String>(dayKey.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SuggestionHistoryCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('dayKey: $dayKey, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('itemId: $itemId, ')
          ..write('outcome: $outcome, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    key,
    value,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;
  final String key;
  final String value;
  const Setting({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      key: Value(key),
      value: Value(value),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? key,
    String? value,
  }) => Setting(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, updatedAt, deletedAt, installId, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AppMetaTable extends AppMeta with TableInfo<$AppMetaTable, AppMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _installIdMeta = const VerificationMeta(
    'installId',
  );
  @override
  late final GeneratedColumn<String> installId = GeneratedColumn<String>(
    'install_id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceInstallIdMeta = const VerificationMeta(
    'deviceInstallId',
  );
  @override
  late final GeneratedColumn<String> deviceInstallId = GeneratedColumn<String>(
    'device_install_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedAtMeta = const VerificationMeta(
    'installedAt',
  );
  @override
  late final GeneratedColumn<int> installedAt = GeneratedColumn<int>(
    'installed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    installId,
    deviceInstallId,
    installedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('install_id')) {
      context.handle(
        _installIdMeta,
        installId.isAcceptableOrUnknown(data['install_id']!, _installIdMeta),
      );
    } else if (isInserting) {
      context.missing(_installIdMeta);
    }
    if (data.containsKey('device_install_id')) {
      context.handle(
        _deviceInstallIdMeta,
        deviceInstallId.isAcceptableOrUnknown(
          data['device_install_id']!,
          _deviceInstallIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_deviceInstallIdMeta);
    }
    if (data.containsKey('installed_at')) {
      context.handle(
        _installedAtMeta,
        installedAt.isAcceptableOrUnknown(
          data['installed_at']!,
          _installedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AppMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetaRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      installId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}install_id'],
      )!,
      deviceInstallId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_install_id'],
      )!,
      installedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}installed_at'],
      )!,
    );
  }

  @override
  $AppMetaTable createAlias(String alias) {
    return $AppMetaTable(attachedDatabase, alias);
  }
}

class AppMetaRow extends DataClass implements Insertable<AppMetaRow> {
  /// UUID v7. **Never an autoincrement integer.**
  ///
  /// Two devices both minting `id = 47` cannot be merged, and merge is the
  /// whole reason this format is also a future sync protocol.
  final String id;

  /// UTC epoch millis of the last change. The merge key.
  ///
  /// Without it, last-writer-wins is impossible and every conflict is a coin
  /// flip.
  final int updatedAt;

  /// Soft delete. A deleted row that leaves no tombstone comes back to life on
  /// the next merge.
  ///
  /// Hard-delete only in an explicit purge, never in normal use.
  final int? deletedAt;

  /// Which install created this row. Tells a future merge which device said
  /// what.
  final String installId;

  /// The id every row written on this device is stamped with.
  final String deviceInstallId;
  final int installedAt;
  const AppMetaRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.installId,
    required this.deviceInstallId,
    required this.installedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    map['install_id'] = Variable<String>(installId);
    map['device_install_id'] = Variable<String>(deviceInstallId);
    map['installed_at'] = Variable<int>(installedAt);
    return map;
  }

  AppMetaCompanion toCompanion(bool nullToAbsent) {
    return AppMetaCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      installId: Value(installId),
      deviceInstallId: Value(deviceInstallId),
      installedAt: Value(installedAt),
    );
  }

  factory AppMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetaRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
      installId: serializer.fromJson<String>(json['installId']),
      deviceInstallId: serializer.fromJson<String>(json['deviceInstallId']),
      installedAt: serializer.fromJson<int>(json['installedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'deletedAt': serializer.toJson<int?>(deletedAt),
      'installId': serializer.toJson<String>(installId),
      'deviceInstallId': serializer.toJson<String>(deviceInstallId),
      'installedAt': serializer.toJson<int>(installedAt),
    };
  }

  AppMetaRow copyWith({
    String? id,
    int? updatedAt,
    Value<int?> deletedAt = const Value.absent(),
    String? installId,
    String? deviceInstallId,
    int? installedAt,
  }) => AppMetaRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    installId: installId ?? this.installId,
    deviceInstallId: deviceInstallId ?? this.deviceInstallId,
    installedAt: installedAt ?? this.installedAt,
  );
  AppMetaRow copyWithCompanion(AppMetaCompanion data) {
    return AppMetaRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      installId: data.installId.present ? data.installId.value : this.installId,
      deviceInstallId: data.deviceInstallId.present
          ? data.deviceInstallId.value
          : this.deviceInstallId,
      installedAt: data.installedAt.present
          ? data.installedAt.value
          : this.installedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('deviceInstallId: $deviceInstallId, ')
          ..write('installedAt: $installedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    installId,
    deviceInstallId,
    installedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetaRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.installId == this.installId &&
          other.deviceInstallId == this.deviceInstallId &&
          other.installedAt == this.installedAt);
}

class AppMetaCompanion extends UpdateCompanion<AppMetaRow> {
  final Value<String> id;
  final Value<int> updatedAt;
  final Value<int?> deletedAt;
  final Value<String> installId;
  final Value<String> deviceInstallId;
  final Value<int> installedAt;
  final Value<int> rowid;
  const AppMetaCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.installId = const Value.absent(),
    this.deviceInstallId = const Value.absent(),
    this.installedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetaCompanion.insert({
    required String id,
    required int updatedAt,
    this.deletedAt = const Value.absent(),
    required String installId,
    required String deviceInstallId,
    required int installedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       updatedAt = Value(updatedAt),
       installId = Value(installId),
       deviceInstallId = Value(deviceInstallId),
       installedAt = Value(installedAt);
  static Insertable<AppMetaRow> custom({
    Expression<String>? id,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<String>? installId,
    Expression<String>? deviceInstallId,
    Expression<int>? installedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (installId != null) 'install_id': installId,
      if (deviceInstallId != null) 'device_install_id': deviceInstallId,
      if (installedAt != null) 'installed_at': installedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetaCompanion copyWith({
    Value<String>? id,
    Value<int>? updatedAt,
    Value<int?>? deletedAt,
    Value<String>? installId,
    Value<String>? deviceInstallId,
    Value<int>? installedAt,
    Value<int>? rowid,
  }) {
    return AppMetaCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      installId: installId ?? this.installId,
      deviceInstallId: deviceInstallId ?? this.deviceInstallId,
      installedAt: installedAt ?? this.installedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (installId.present) {
      map['install_id'] = Variable<String>(installId.value);
    }
    if (deviceInstallId.present) {
      map['device_install_id'] = Variable<String>(deviceInstallId.value);
    }
    if (installedAt.present) {
      map['installed_at'] = Variable<int>(installedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetaCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('installId: $installId, ')
          ..write('deviceInstallId: $deviceInstallId, ')
          ..write('installedAt: $installedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$TallyDatabase extends GeneratedDatabase {
  _$TallyDatabase(QueryExecutor e) : super(e);
  $TallyDatabaseManager get managers => $TallyDatabaseManager(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $PlanEntriesTable planEntries = $PlanEntriesTable(this);
  late final $WatchedAppsTable watchedApps = $WatchedAppsTable(this);
  late final $UsageCheckpointsTable usageCheckpoints = $UsageCheckpointsTable(
    this,
  );
  late final $DayLedgerTable dayLedger = $DayLedgerTable(this);
  late final $DaySpendTable daySpend = $DaySpendTable(this);
  late final $TreatsTable treats = $TreatsTable(this);
  late final $SavingsTransfersTable savingsTransfers = $SavingsTransfersTable(
    this,
  );
  late final $StickerStampsTable stickerStamps = $StickerStampsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $SuggestionHistoryTable suggestionHistory =
      $SuggestionHistoryTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $AppMetaTable appMeta = $AppMetaTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    tasks,
    projects,
    sessions,
    planEntries,
    watchedApps,
    usageCheckpoints,
    dayLedger,
    daySpend,
    treats,
    savingsTransfers,
    stickerStamps,
    goals,
    suggestionHistory,
    settings,
    appMeta,
  ];
}

typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String kind,
      required String title,
      Value<String?> stickerId,
      Value<int?> estimateMinutes,
      Value<String?> projectId,
      Value<String> habitWeekdays,
      required int createdAt,
      Value<int?> lastCompletedAt,
      Value<int?> archivedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> kind,
      Value<String> title,
      Value<String?> stickerId,
      Value<int?> estimateMinutes,
      Value<String?> projectId,
      Value<String> habitWeekdays,
      Value<int> createdAt,
      Value<int?> lastCompletedAt,
      Value<int?> archivedAt,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer
    extends Composer<_$TallyDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get habitWeekdays => $composableBuilder(
    column: $table.habitWeekdays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$TallyDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get projectId => $composableBuilder(
    column: $table.projectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get habitWeekdays => $composableBuilder(
    column: $table.habitWeekdays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$TallyDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get stickerId =>
      $composableBuilder(column: $table.stickerId, builder: (column) => column);

  GeneratedColumn<int> get estimateMinutes => $composableBuilder(
    column: $table.estimateMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get habitWeekdays => $composableBuilder(
    column: $table.habitWeekdays,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get lastCompletedAt => $composableBuilder(
    column: $table.lastCompletedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$TallyDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$TallyDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> stickerId = const Value.absent(),
                Value<int?> estimateMinutes = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> habitWeekdays = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> lastCompletedAt = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                kind: kind,
                title: title,
                stickerId: stickerId,
                estimateMinutes: estimateMinutes,
                projectId: projectId,
                habitWeekdays: habitWeekdays,
                createdAt: createdAt,
                lastCompletedAt: lastCompletedAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String kind,
                required String title,
                Value<String?> stickerId = const Value.absent(),
                Value<int?> estimateMinutes = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String> habitWeekdays = const Value.absent(),
                required int createdAt,
                Value<int?> lastCompletedAt = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                kind: kind,
                title: title,
                stickerId: stickerId,
                estimateMinutes: estimateMinutes,
                projectId: projectId,
                habitWeekdays: habitWeekdays,
                createdAt: createdAt,
                lastCompletedAt: lastCompletedAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$TallyDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$ProjectsTableCreateCompanionBuilder =
    ProjectsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String name,
      Value<String?> stickerId,
      required int createdAt,
      Value<int?> archivedAt,
      Value<int> rowid,
    });
typedef $$ProjectsTableUpdateCompanionBuilder =
    ProjectsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> name,
      Value<String?> stickerId,
      Value<int> createdAt,
      Value<int?> archivedAt,
      Value<int> rowid,
    });

class $$ProjectsTableFilterComposer
    extends Composer<_$TallyDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$TallyDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$TallyDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get stickerId =>
      $composableBuilder(column: $table.stickerId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $ProjectsTable,
          Project,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (Project, BaseReferences<_$TallyDatabase, $ProjectsTable, Project>),
          Project,
          PrefetchHooks Function()
        > {
  $$ProjectsTableTableManager(_$TallyDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> stickerId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                name: name,
                stickerId: stickerId,
                createdAt: createdAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String name,
                Value<String?> stickerId = const Value.absent(),
                required int createdAt,
                Value<int?> archivedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                name: name,
                stickerId: stickerId,
                createdAt: createdAt,
                archivedAt: archivedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $ProjectsTable,
      Project,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (Project, BaseReferences<_$TallyDatabase, $ProjectsTable, Project>),
      Project,
      PrefetchHooks Function()
    >;
typedef $$SessionsTableCreateCompanionBuilder =
    SessionsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      Value<String?> taskId,
      required int startedAt,
      required int endedAt,
      Value<bool> phoneDownVerified,
      Value<int> rowid,
    });
typedef $$SessionsTableUpdateCompanionBuilder =
    SessionsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<String?> taskId,
      Value<int> startedAt,
      Value<int> endedAt,
      Value<bool> phoneDownVerified,
      Value<int> rowid,
    });

class $$SessionsTableFilterComposer
    extends Composer<_$TallyDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get phoneDownVerified => $composableBuilder(
    column: $table.phoneDownVerified,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SessionsTableOrderingComposer
    extends Composer<_$TallyDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get phoneDownVerified => $composableBuilder(
    column: $table.phoneDownVerified,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$TallyDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<bool> get phoneDownVerified => $composableBuilder(
    column: $table.phoneDownVerified,
    builder: (column) => column,
  );
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, BaseReferences<_$TallyDatabase, $SessionsTable, Session>),
          Session,
          PrefetchHooks Function()
        > {
  $$SessionsTableTableManager(_$TallyDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
                Value<int> endedAt = const Value.absent(),
                Value<bool> phoneDownVerified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                taskId: taskId,
                startedAt: startedAt,
                endedAt: endedAt,
                phoneDownVerified: phoneDownVerified,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                Value<String?> taskId = const Value.absent(),
                required int startedAt,
                required int endedAt,
                Value<bool> phoneDownVerified = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                taskId: taskId,
                startedAt: startedAt,
                endedAt: endedAt,
                phoneDownVerified: phoneDownVerified,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, BaseReferences<_$TallyDatabase, $SessionsTable, Session>),
      Session,
      PrefetchHooks Function()
    >;
typedef $$PlanEntriesTableCreateCompanionBuilder =
    PlanEntriesCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      required String taskId,
      required int sortOrder,
      required String source,
      Value<int?> doneAt,
      Value<int> rowid,
    });
typedef $$PlanEntriesTableUpdateCompanionBuilder =
    PlanEntriesCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<String> taskId,
      Value<int> sortOrder,
      Value<String> source,
      Value<int?> doneAt,
      Value<int> rowid,
    });

class $$PlanEntriesTableFilterComposer
    extends Composer<_$TallyDatabase, $PlanEntriesTable> {
  $$PlanEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PlanEntriesTableOrderingComposer
    extends Composer<_$TallyDatabase, $PlanEntriesTable> {
  $$PlanEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get doneAt => $composableBuilder(
    column: $table.doneAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PlanEntriesTableAnnotationComposer
    extends Composer<_$TallyDatabase, $PlanEntriesTable> {
  $$PlanEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get doneAt =>
      $composableBuilder(column: $table.doneAt, builder: (column) => column);
}

class $$PlanEntriesTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $PlanEntriesTable,
          PlanEntry,
          $$PlanEntriesTableFilterComposer,
          $$PlanEntriesTableOrderingComposer,
          $$PlanEntriesTableAnnotationComposer,
          $$PlanEntriesTableCreateCompanionBuilder,
          $$PlanEntriesTableUpdateCompanionBuilder,
          (
            PlanEntry,
            BaseReferences<_$TallyDatabase, $PlanEntriesTable, PlanEntry>,
          ),
          PlanEntry,
          PrefetchHooks Function()
        > {
  $$PlanEntriesTableTableManager(_$TallyDatabase db, $PlanEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlanEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlanEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlanEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int?> doneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanEntriesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                taskId: taskId,
                sortOrder: sortOrder,
                source: source,
                doneAt: doneAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                required String taskId,
                required int sortOrder,
                required String source,
                Value<int?> doneAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PlanEntriesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                taskId: taskId,
                sortOrder: sortOrder,
                source: source,
                doneAt: doneAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PlanEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $PlanEntriesTable,
      PlanEntry,
      $$PlanEntriesTableFilterComposer,
      $$PlanEntriesTableOrderingComposer,
      $$PlanEntriesTableAnnotationComposer,
      $$PlanEntriesTableCreateCompanionBuilder,
      $$PlanEntriesTableUpdateCompanionBuilder,
      (
        PlanEntry,
        BaseReferences<_$TallyDatabase, $PlanEntriesTable, PlanEntry>,
      ),
      PlanEntry,
      PrefetchHooks Function()
    >;
typedef $$WatchedAppsTableCreateCompanionBuilder =
    WatchedAppsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String packageName,
      required String label,
      Value<bool> watching,
      required int addedAt,
      Value<int?> removedAt,
      Value<bool> notInstalled,
      Value<int> rowid,
    });
typedef $$WatchedAppsTableUpdateCompanionBuilder =
    WatchedAppsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> packageName,
      Value<String> label,
      Value<bool> watching,
      Value<int> addedAt,
      Value<int?> removedAt,
      Value<bool> notInstalled,
      Value<int> rowid,
    });

class $$WatchedAppsTableFilterComposer
    extends Composer<_$TallyDatabase, $WatchedAppsTable> {
  $$WatchedAppsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get watching => $composableBuilder(
    column: $table.watching,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notInstalled => $composableBuilder(
    column: $table.notInstalled,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WatchedAppsTableOrderingComposer
    extends Composer<_$TallyDatabase, $WatchedAppsTable> {
  $$WatchedAppsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get watching => $composableBuilder(
    column: $table.watching,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get removedAt => $composableBuilder(
    column: $table.removedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notInstalled => $composableBuilder(
    column: $table.notInstalled,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WatchedAppsTableAnnotationComposer
    extends Composer<_$TallyDatabase, $WatchedAppsTable> {
  $$WatchedAppsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<bool> get watching =>
      $composableBuilder(column: $table.watching, builder: (column) => column);

  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get removedAt =>
      $composableBuilder(column: $table.removedAt, builder: (column) => column);

  GeneratedColumn<bool> get notInstalled => $composableBuilder(
    column: $table.notInstalled,
    builder: (column) => column,
  );
}

class $$WatchedAppsTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $WatchedAppsTable,
          WatchedApp,
          $$WatchedAppsTableFilterComposer,
          $$WatchedAppsTableOrderingComposer,
          $$WatchedAppsTableAnnotationComposer,
          $$WatchedAppsTableCreateCompanionBuilder,
          $$WatchedAppsTableUpdateCompanionBuilder,
          (
            WatchedApp,
            BaseReferences<_$TallyDatabase, $WatchedAppsTable, WatchedApp>,
          ),
          WatchedApp,
          PrefetchHooks Function()
        > {
  $$WatchedAppsTableTableManager(_$TallyDatabase db, $WatchedAppsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchedAppsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchedAppsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchedAppsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<bool> watching = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int?> removedAt = const Value.absent(),
                Value<bool> notInstalled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchedAppsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                packageName: packageName,
                label: label,
                watching: watching,
                addedAt: addedAt,
                removedAt: removedAt,
                notInstalled: notInstalled,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String packageName,
                required String label,
                Value<bool> watching = const Value.absent(),
                required int addedAt,
                Value<int?> removedAt = const Value.absent(),
                Value<bool> notInstalled = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchedAppsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                packageName: packageName,
                label: label,
                watching: watching,
                addedAt: addedAt,
                removedAt: removedAt,
                notInstalled: notInstalled,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WatchedAppsTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $WatchedAppsTable,
      WatchedApp,
      $$WatchedAppsTableFilterComposer,
      $$WatchedAppsTableOrderingComposer,
      $$WatchedAppsTableAnnotationComposer,
      $$WatchedAppsTableCreateCompanionBuilder,
      $$WatchedAppsTableUpdateCompanionBuilder,
      (
        WatchedApp,
        BaseReferences<_$TallyDatabase, $WatchedAppsTable, WatchedApp>,
      ),
      WatchedApp,
      PrefetchHooks Function()
    >;
typedef $$UsageCheckpointsTableCreateCompanionBuilder =
    UsageCheckpointsCompanion Function({
      Value<int> id,
      required int reconciledThrough,
      required int recordedAt,
    });
typedef $$UsageCheckpointsTableUpdateCompanionBuilder =
    UsageCheckpointsCompanion Function({
      Value<int> id,
      Value<int> reconciledThrough,
      Value<int> recordedAt,
    });

class $$UsageCheckpointsTableFilterComposer
    extends Composer<_$TallyDatabase, $UsageCheckpointsTable> {
  $$UsageCheckpointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reconciledThrough => $composableBuilder(
    column: $table.reconciledThrough,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsageCheckpointsTableOrderingComposer
    extends Composer<_$TallyDatabase, $UsageCheckpointsTable> {
  $$UsageCheckpointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reconciledThrough => $composableBuilder(
    column: $table.reconciledThrough,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsageCheckpointsTableAnnotationComposer
    extends Composer<_$TallyDatabase, $UsageCheckpointsTable> {
  $$UsageCheckpointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get reconciledThrough => $composableBuilder(
    column: $table.reconciledThrough,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );
}

class $$UsageCheckpointsTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $UsageCheckpointsTable,
          UsageCheckpoint,
          $$UsageCheckpointsTableFilterComposer,
          $$UsageCheckpointsTableOrderingComposer,
          $$UsageCheckpointsTableAnnotationComposer,
          $$UsageCheckpointsTableCreateCompanionBuilder,
          $$UsageCheckpointsTableUpdateCompanionBuilder,
          (
            UsageCheckpoint,
            BaseReferences<
              _$TallyDatabase,
              $UsageCheckpointsTable,
              UsageCheckpoint
            >,
          ),
          UsageCheckpoint,
          PrefetchHooks Function()
        > {
  $$UsageCheckpointsTableTableManager(
    _$TallyDatabase db,
    $UsageCheckpointsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsageCheckpointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsageCheckpointsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsageCheckpointsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> reconciledThrough = const Value.absent(),
                Value<int> recordedAt = const Value.absent(),
              }) => UsageCheckpointsCompanion(
                id: id,
                reconciledThrough: reconciledThrough,
                recordedAt: recordedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int reconciledThrough,
                required int recordedAt,
              }) => UsageCheckpointsCompanion.insert(
                id: id,
                reconciledThrough: reconciledThrough,
                recordedAt: recordedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsageCheckpointsTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $UsageCheckpointsTable,
      UsageCheckpoint,
      $$UsageCheckpointsTableFilterComposer,
      $$UsageCheckpointsTableOrderingComposer,
      $$UsageCheckpointsTableAnnotationComposer,
      $$UsageCheckpointsTableCreateCompanionBuilder,
      $$UsageCheckpointsTableUpdateCompanionBuilder,
      (
        UsageCheckpoint,
        BaseReferences<
          _$TallyDatabase,
          $UsageCheckpointsTable,
          UsageCheckpoint
        >,
      ),
      UsageCheckpoint,
      PrefetchHooks Function()
    >;
typedef $$DayLedgerTableCreateCompanionBuilder =
    DayLedgerCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      required int allowanceGrantedSeconds,
      required int allowanceToDebtSeconds,
      required int earnedSeconds,
      required int earnCappedSeconds,
      required int spentSeconds,
      required int graceUsedSeconds,
      required int unrepayableSeconds,
      required int closingBalanceSeconds,
      required int closingSavingsSeconds,
      required int overflowToSavingsSeconds,
      required int treatedSeconds,
      required bool solvent,
      Value<int> rowid,
    });
typedef $$DayLedgerTableUpdateCompanionBuilder =
    DayLedgerCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<int> allowanceGrantedSeconds,
      Value<int> allowanceToDebtSeconds,
      Value<int> earnedSeconds,
      Value<int> earnCappedSeconds,
      Value<int> spentSeconds,
      Value<int> graceUsedSeconds,
      Value<int> unrepayableSeconds,
      Value<int> closingBalanceSeconds,
      Value<int> closingSavingsSeconds,
      Value<int> overflowToSavingsSeconds,
      Value<int> treatedSeconds,
      Value<bool> solvent,
      Value<int> rowid,
    });

class $$DayLedgerTableFilterComposer
    extends Composer<_$TallyDatabase, $DayLedgerTable> {
  $$DayLedgerTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allowanceGrantedSeconds => $composableBuilder(
    column: $table.allowanceGrantedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get allowanceToDebtSeconds => $composableBuilder(
    column: $table.allowanceToDebtSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get earnedSeconds => $composableBuilder(
    column: $table.earnedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get earnCappedSeconds => $composableBuilder(
    column: $table.earnCappedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get spentSeconds => $composableBuilder(
    column: $table.spentSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get graceUsedSeconds => $composableBuilder(
    column: $table.graceUsedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unrepayableSeconds => $composableBuilder(
    column: $table.unrepayableSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closingBalanceSeconds => $composableBuilder(
    column: $table.closingBalanceSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get closingSavingsSeconds => $composableBuilder(
    column: $table.closingSavingsSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get overflowToSavingsSeconds => $composableBuilder(
    column: $table.overflowToSavingsSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get treatedSeconds => $composableBuilder(
    column: $table.treatedSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get solvent => $composableBuilder(
    column: $table.solvent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DayLedgerTableOrderingComposer
    extends Composer<_$TallyDatabase, $DayLedgerTable> {
  $$DayLedgerTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allowanceGrantedSeconds => $composableBuilder(
    column: $table.allowanceGrantedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get allowanceToDebtSeconds => $composableBuilder(
    column: $table.allowanceToDebtSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get earnedSeconds => $composableBuilder(
    column: $table.earnedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get earnCappedSeconds => $composableBuilder(
    column: $table.earnCappedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get spentSeconds => $composableBuilder(
    column: $table.spentSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get graceUsedSeconds => $composableBuilder(
    column: $table.graceUsedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unrepayableSeconds => $composableBuilder(
    column: $table.unrepayableSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closingBalanceSeconds => $composableBuilder(
    column: $table.closingBalanceSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get closingSavingsSeconds => $composableBuilder(
    column: $table.closingSavingsSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get overflowToSavingsSeconds => $composableBuilder(
    column: $table.overflowToSavingsSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get treatedSeconds => $composableBuilder(
    column: $table.treatedSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get solvent => $composableBuilder(
    column: $table.solvent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DayLedgerTableAnnotationComposer
    extends Composer<_$TallyDatabase, $DayLedgerTable> {
  $$DayLedgerTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get allowanceGrantedSeconds => $composableBuilder(
    column: $table.allowanceGrantedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get allowanceToDebtSeconds => $composableBuilder(
    column: $table.allowanceToDebtSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get earnedSeconds => $composableBuilder(
    column: $table.earnedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get earnCappedSeconds => $composableBuilder(
    column: $table.earnCappedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get spentSeconds => $composableBuilder(
    column: $table.spentSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get graceUsedSeconds => $composableBuilder(
    column: $table.graceUsedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unrepayableSeconds => $composableBuilder(
    column: $table.unrepayableSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closingBalanceSeconds => $composableBuilder(
    column: $table.closingBalanceSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get closingSavingsSeconds => $composableBuilder(
    column: $table.closingSavingsSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get overflowToSavingsSeconds => $composableBuilder(
    column: $table.overflowToSavingsSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get treatedSeconds => $composableBuilder(
    column: $table.treatedSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get solvent =>
      $composableBuilder(column: $table.solvent, builder: (column) => column);
}

class $$DayLedgerTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $DayLedgerTable,
          DayLedgerData,
          $$DayLedgerTableFilterComposer,
          $$DayLedgerTableOrderingComposer,
          $$DayLedgerTableAnnotationComposer,
          $$DayLedgerTableCreateCompanionBuilder,
          $$DayLedgerTableUpdateCompanionBuilder,
          (
            DayLedgerData,
            BaseReferences<_$TallyDatabase, $DayLedgerTable, DayLedgerData>,
          ),
          DayLedgerData,
          PrefetchHooks Function()
        > {
  $$DayLedgerTableTableManager(_$TallyDatabase db, $DayLedgerTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DayLedgerTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DayLedgerTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DayLedgerTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<int> allowanceGrantedSeconds = const Value.absent(),
                Value<int> allowanceToDebtSeconds = const Value.absent(),
                Value<int> earnedSeconds = const Value.absent(),
                Value<int> earnCappedSeconds = const Value.absent(),
                Value<int> spentSeconds = const Value.absent(),
                Value<int> graceUsedSeconds = const Value.absent(),
                Value<int> unrepayableSeconds = const Value.absent(),
                Value<int> closingBalanceSeconds = const Value.absent(),
                Value<int> closingSavingsSeconds = const Value.absent(),
                Value<int> overflowToSavingsSeconds = const Value.absent(),
                Value<int> treatedSeconds = const Value.absent(),
                Value<bool> solvent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DayLedgerCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                allowanceGrantedSeconds: allowanceGrantedSeconds,
                allowanceToDebtSeconds: allowanceToDebtSeconds,
                earnedSeconds: earnedSeconds,
                earnCappedSeconds: earnCappedSeconds,
                spentSeconds: spentSeconds,
                graceUsedSeconds: graceUsedSeconds,
                unrepayableSeconds: unrepayableSeconds,
                closingBalanceSeconds: closingBalanceSeconds,
                closingSavingsSeconds: closingSavingsSeconds,
                overflowToSavingsSeconds: overflowToSavingsSeconds,
                treatedSeconds: treatedSeconds,
                solvent: solvent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                required int allowanceGrantedSeconds,
                required int allowanceToDebtSeconds,
                required int earnedSeconds,
                required int earnCappedSeconds,
                required int spentSeconds,
                required int graceUsedSeconds,
                required int unrepayableSeconds,
                required int closingBalanceSeconds,
                required int closingSavingsSeconds,
                required int overflowToSavingsSeconds,
                required int treatedSeconds,
                required bool solvent,
                Value<int> rowid = const Value.absent(),
              }) => DayLedgerCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                allowanceGrantedSeconds: allowanceGrantedSeconds,
                allowanceToDebtSeconds: allowanceToDebtSeconds,
                earnedSeconds: earnedSeconds,
                earnCappedSeconds: earnCappedSeconds,
                spentSeconds: spentSeconds,
                graceUsedSeconds: graceUsedSeconds,
                unrepayableSeconds: unrepayableSeconds,
                closingBalanceSeconds: closingBalanceSeconds,
                closingSavingsSeconds: closingSavingsSeconds,
                overflowToSavingsSeconds: overflowToSavingsSeconds,
                treatedSeconds: treatedSeconds,
                solvent: solvent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DayLedgerTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $DayLedgerTable,
      DayLedgerData,
      $$DayLedgerTableFilterComposer,
      $$DayLedgerTableOrderingComposer,
      $$DayLedgerTableAnnotationComposer,
      $$DayLedgerTableCreateCompanionBuilder,
      $$DayLedgerTableUpdateCompanionBuilder,
      (
        DayLedgerData,
        BaseReferences<_$TallyDatabase, $DayLedgerTable, DayLedgerData>,
      ),
      DayLedgerData,
      PrefetchHooks Function()
    >;
typedef $$DaySpendTableCreateCompanionBuilder =
    DaySpendCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      required String packageName,
      required int seconds,
      Value<int> rowid,
    });
typedef $$DaySpendTableUpdateCompanionBuilder =
    DaySpendCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<String> packageName,
      Value<int> seconds,
      Value<int> rowid,
    });

class $$DaySpendTableFilterComposer
    extends Composer<_$TallyDatabase, $DaySpendTable> {
  $$DaySpendTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DaySpendTableOrderingComposer
    extends Composer<_$TallyDatabase, $DaySpendTable> {
  $$DaySpendTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DaySpendTableAnnotationComposer
    extends Composer<_$TallyDatabase, $DaySpendTable> {
  $$DaySpendTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get packageName => $composableBuilder(
    column: $table.packageName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);
}

class $$DaySpendTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $DaySpendTable,
          DaySpendData,
          $$DaySpendTableFilterComposer,
          $$DaySpendTableOrderingComposer,
          $$DaySpendTableAnnotationComposer,
          $$DaySpendTableCreateCompanionBuilder,
          $$DaySpendTableUpdateCompanionBuilder,
          (
            DaySpendData,
            BaseReferences<_$TallyDatabase, $DaySpendTable, DaySpendData>,
          ),
          DaySpendData,
          PrefetchHooks Function()
        > {
  $$DaySpendTableTableManager(_$TallyDatabase db, $DaySpendTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DaySpendTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DaySpendTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DaySpendTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<String> packageName = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DaySpendCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                packageName: packageName,
                seconds: seconds,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                required String packageName,
                required int seconds,
                Value<int> rowid = const Value.absent(),
              }) => DaySpendCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                packageName: packageName,
                seconds: seconds,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DaySpendTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $DaySpendTable,
      DaySpendData,
      $$DaySpendTableFilterComposer,
      $$DaySpendTableOrderingComposer,
      $$DaySpendTableAnnotationComposer,
      $$DaySpendTableCreateCompanionBuilder,
      $$DaySpendTableUpdateCompanionBuilder,
      (
        DaySpendData,
        BaseReferences<_$TallyDatabase, $DaySpendTable, DaySpendData>,
      ),
      DaySpendData,
      PrefetchHooks Function()
    >;
typedef $$TreatsTableCreateCompanionBuilder =
    TreatsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      required int minutesBurned,
      required String label,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$TreatsTableUpdateCompanionBuilder =
    TreatsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<int> minutesBurned,
      Value<String> label,
      Value<String?> note,
      Value<int> rowid,
    });

class $$TreatsTableFilterComposer
    extends Composer<_$TallyDatabase, $TreatsTable> {
  $$TreatsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutesBurned => $composableBuilder(
    column: $table.minutesBurned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TreatsTableOrderingComposer
    extends Composer<_$TallyDatabase, $TreatsTable> {
  $$TreatsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutesBurned => $composableBuilder(
    column: $table.minutesBurned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TreatsTableAnnotationComposer
    extends Composer<_$TallyDatabase, $TreatsTable> {
  $$TreatsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get minutesBurned => $composableBuilder(
    column: $table.minutesBurned,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$TreatsTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $TreatsTable,
          Treat,
          $$TreatsTableFilterComposer,
          $$TreatsTableOrderingComposer,
          $$TreatsTableAnnotationComposer,
          $$TreatsTableCreateCompanionBuilder,
          $$TreatsTableUpdateCompanionBuilder,
          (Treat, BaseReferences<_$TallyDatabase, $TreatsTable, Treat>),
          Treat,
          PrefetchHooks Function()
        > {
  $$TreatsTableTableManager(_$TallyDatabase db, $TreatsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TreatsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TreatsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TreatsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<int> minutesBurned = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TreatsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                minutesBurned: minutesBurned,
                label: label,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                required int minutesBurned,
                required String label,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TreatsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                minutesBurned: minutesBurned,
                label: label,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TreatsTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $TreatsTable,
      Treat,
      $$TreatsTableFilterComposer,
      $$TreatsTableOrderingComposer,
      $$TreatsTableAnnotationComposer,
      $$TreatsTableCreateCompanionBuilder,
      $$TreatsTableUpdateCompanionBuilder,
      (Treat, BaseReferences<_$TallyDatabase, $TreatsTable, Treat>),
      Treat,
      PrefetchHooks Function()
    >;
typedef $$SavingsTransfersTableCreateCompanionBuilder =
    SavingsTransfersCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      required int seconds,
      required bool toSavings,
      Value<int> rowid,
    });
typedef $$SavingsTransfersTableUpdateCompanionBuilder =
    SavingsTransfersCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<int> seconds,
      Value<bool> toSavings,
      Value<int> rowid,
    });

class $$SavingsTransfersTableFilterComposer
    extends Composer<_$TallyDatabase, $SavingsTransfersTable> {
  $$SavingsTransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get toSavings => $composableBuilder(
    column: $table.toSavings,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SavingsTransfersTableOrderingComposer
    extends Composer<_$TallyDatabase, $SavingsTransfersTable> {
  $$SavingsTransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seconds => $composableBuilder(
    column: $table.seconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get toSavings => $composableBuilder(
    column: $table.toSavings,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SavingsTransfersTableAnnotationComposer
    extends Composer<_$TallyDatabase, $SavingsTransfersTable> {
  $$SavingsTransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get seconds =>
      $composableBuilder(column: $table.seconds, builder: (column) => column);

  GeneratedColumn<bool> get toSavings =>
      $composableBuilder(column: $table.toSavings, builder: (column) => column);
}

class $$SavingsTransfersTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $SavingsTransfersTable,
          SavingsTransfer,
          $$SavingsTransfersTableFilterComposer,
          $$SavingsTransfersTableOrderingComposer,
          $$SavingsTransfersTableAnnotationComposer,
          $$SavingsTransfersTableCreateCompanionBuilder,
          $$SavingsTransfersTableUpdateCompanionBuilder,
          (
            SavingsTransfer,
            BaseReferences<
              _$TallyDatabase,
              $SavingsTransfersTable,
              SavingsTransfer
            >,
          ),
          SavingsTransfer,
          PrefetchHooks Function()
        > {
  $$SavingsTransfersTableTableManager(
    _$TallyDatabase db,
    $SavingsTransfersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SavingsTransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SavingsTransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SavingsTransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<int> seconds = const Value.absent(),
                Value<bool> toSavings = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SavingsTransfersCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                seconds: seconds,
                toSavings: toSavings,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                required int seconds,
                required bool toSavings,
                Value<int> rowid = const Value.absent(),
              }) => SavingsTransfersCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                seconds: seconds,
                toSavings: toSavings,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SavingsTransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $SavingsTransfersTable,
      SavingsTransfer,
      $$SavingsTransfersTableFilterComposer,
      $$SavingsTransfersTableOrderingComposer,
      $$SavingsTransfersTableAnnotationComposer,
      $$SavingsTransfersTableCreateCompanionBuilder,
      $$SavingsTransfersTableUpdateCompanionBuilder,
      (
        SavingsTransfer,
        BaseReferences<
          _$TallyDatabase,
          $SavingsTransfersTable,
          SavingsTransfer
        >,
      ),
      SavingsTransfer,
      PrefetchHooks Function()
    >;
typedef $$StickerStampsTableCreateCompanionBuilder =
    StickerStampsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      required String stickerId,
      required String taskId,
      required int stampedAt,
      Value<int> rowid,
    });
typedef $$StickerStampsTableUpdateCompanionBuilder =
    StickerStampsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<String> stickerId,
      Value<String> taskId,
      Value<int> stampedAt,
      Value<int> rowid,
    });

class $$StickerStampsTableFilterComposer
    extends Composer<_$TallyDatabase, $StickerStampsTable> {
  $$StickerStampsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stampedAt => $composableBuilder(
    column: $table.stampedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$StickerStampsTableOrderingComposer
    extends Composer<_$TallyDatabase, $StickerStampsTable> {
  $$StickerStampsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskId => $composableBuilder(
    column: $table.taskId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stampedAt => $composableBuilder(
    column: $table.stampedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StickerStampsTableAnnotationComposer
    extends Composer<_$TallyDatabase, $StickerStampsTable> {
  $$StickerStampsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get stickerId =>
      $composableBuilder(column: $table.stickerId, builder: (column) => column);

  GeneratedColumn<String> get taskId =>
      $composableBuilder(column: $table.taskId, builder: (column) => column);

  GeneratedColumn<int> get stampedAt =>
      $composableBuilder(column: $table.stampedAt, builder: (column) => column);
}

class $$StickerStampsTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $StickerStampsTable,
          StickerStamp,
          $$StickerStampsTableFilterComposer,
          $$StickerStampsTableOrderingComposer,
          $$StickerStampsTableAnnotationComposer,
          $$StickerStampsTableCreateCompanionBuilder,
          $$StickerStampsTableUpdateCompanionBuilder,
          (
            StickerStamp,
            BaseReferences<_$TallyDatabase, $StickerStampsTable, StickerStamp>,
          ),
          StickerStamp,
          PrefetchHooks Function()
        > {
  $$StickerStampsTableTableManager(
    _$TallyDatabase db,
    $StickerStampsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StickerStampsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StickerStampsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StickerStampsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<String> stickerId = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<int> stampedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StickerStampsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                stickerId: stickerId,
                taskId: taskId,
                stampedAt: stampedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                required String stickerId,
                required String taskId,
                required int stampedAt,
                Value<int> rowid = const Value.absent(),
              }) => StickerStampsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                stickerId: stickerId,
                taskId: taskId,
                stampedAt: stampedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$StickerStampsTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $StickerStampsTable,
      StickerStamp,
      $$StickerStampsTableFilterComposer,
      $$StickerStampsTableOrderingComposer,
      $$StickerStampsTableAnnotationComposer,
      $$StickerStampsTableCreateCompanionBuilder,
      $$StickerStampsTableUpdateCompanionBuilder,
      (
        StickerStamp,
        BaseReferences<_$TallyDatabase, $StickerStampsTable, StickerStamp>,
      ),
      StickerStamp,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String scope,
      required String title,
      Value<String?> note,
      Value<String?> stickerId,
      Value<String?> linkedProjectId,
      required int createdAt,
      Value<int?> achievedAt,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> scope,
      Value<String> title,
      Value<String?> note,
      Value<String?> stickerId,
      Value<String?> linkedProjectId,
      Value<int> createdAt,
      Value<int?> achievedAt,
      Value<int> rowid,
    });

class $$GoalsTableFilterComposer
    extends Composer<_$TallyDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedProjectId => $composableBuilder(
    column: $table.linkedProjectId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$TallyDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scope => $composableBuilder(
    column: $table.scope,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stickerId => $composableBuilder(
    column: $table.stickerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedProjectId => $composableBuilder(
    column: $table.linkedProjectId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$TallyDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get stickerId =>
      $composableBuilder(column: $table.stickerId, builder: (column) => column);

  GeneratedColumn<String> get linkedProjectId => $composableBuilder(
    column: $table.linkedProjectId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get achievedAt => $composableBuilder(
    column: $table.achievedAt,
    builder: (column) => column,
  );
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$TallyDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$TallyDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> stickerId = const Value.absent(),
                Value<String?> linkedProjectId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int?> achievedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                scope: scope,
                title: title,
                note: note,
                stickerId: stickerId,
                linkedProjectId: linkedProjectId,
                createdAt: createdAt,
                achievedAt: achievedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String scope,
                required String title,
                Value<String?> note = const Value.absent(),
                Value<String?> stickerId = const Value.absent(),
                Value<String?> linkedProjectId = const Value.absent(),
                required int createdAt,
                Value<int?> achievedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                scope: scope,
                title: title,
                note: note,
                stickerId: stickerId,
                linkedProjectId: linkedProjectId,
                createdAt: createdAt,
                achievedAt: achievedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$TallyDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$SuggestionHistoryTableCreateCompanionBuilder =
    SuggestionHistoryCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String dayKey,
      required int tzOffsetMinutes,
      required String itemId,
      required String outcome,
      Value<int> rowid,
    });
typedef $$SuggestionHistoryTableUpdateCompanionBuilder =
    SuggestionHistoryCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> dayKey,
      Value<int> tzOffsetMinutes,
      Value<String> itemId,
      Value<String> outcome,
      Value<int> rowid,
    });

class $$SuggestionHistoryTableFilterComposer
    extends Composer<_$TallyDatabase, $SuggestionHistoryTable> {
  $$SuggestionHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SuggestionHistoryTableOrderingComposer
    extends Composer<_$TallyDatabase, $SuggestionHistoryTable> {
  $$SuggestionHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dayKey => $composableBuilder(
    column: $table.dayKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get outcome => $composableBuilder(
    column: $table.outcome,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SuggestionHistoryTableAnnotationComposer
    extends Composer<_$TallyDatabase, $SuggestionHistoryTable> {
  $$SuggestionHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get dayKey =>
      $composableBuilder(column: $table.dayKey, builder: (column) => column);

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<String> get outcome =>
      $composableBuilder(column: $table.outcome, builder: (column) => column);
}

class $$SuggestionHistoryTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $SuggestionHistoryTable,
          SuggestionHistoryData,
          $$SuggestionHistoryTableFilterComposer,
          $$SuggestionHistoryTableOrderingComposer,
          $$SuggestionHistoryTableAnnotationComposer,
          $$SuggestionHistoryTableCreateCompanionBuilder,
          $$SuggestionHistoryTableUpdateCompanionBuilder,
          (
            SuggestionHistoryData,
            BaseReferences<
              _$TallyDatabase,
              $SuggestionHistoryTable,
              SuggestionHistoryData
            >,
          ),
          SuggestionHistoryData,
          PrefetchHooks Function()
        > {
  $$SuggestionHistoryTableTableManager(
    _$TallyDatabase db,
    $SuggestionHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SuggestionHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SuggestionHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SuggestionHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> dayKey = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<String> outcome = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SuggestionHistoryCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                itemId: itemId,
                outcome: outcome,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String dayKey,
                required int tzOffsetMinutes,
                required String itemId,
                required String outcome,
                Value<int> rowid = const Value.absent(),
              }) => SuggestionHistoryCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                dayKey: dayKey,
                tzOffsetMinutes: tzOffsetMinutes,
                itemId: itemId,
                outcome: outcome,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SuggestionHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $SuggestionHistoryTable,
      SuggestionHistoryData,
      $$SuggestionHistoryTableFilterComposer,
      $$SuggestionHistoryTableOrderingComposer,
      $$SuggestionHistoryTableAnnotationComposer,
      $$SuggestionHistoryTableCreateCompanionBuilder,
      $$SuggestionHistoryTableUpdateCompanionBuilder,
      (
        SuggestionHistoryData,
        BaseReferences<
          _$TallyDatabase,
          $SuggestionHistoryTable,
          SuggestionHistoryData
        >,
      ),
      SuggestionHistoryData,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$TallyDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$TallyDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$TallyDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$TallyDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$TallyDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$TallyDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$AppMetaTableCreateCompanionBuilder =
    AppMetaCompanion Function({
      required String id,
      required int updatedAt,
      Value<int?> deletedAt,
      required String installId,
      required String deviceInstallId,
      required int installedAt,
      Value<int> rowid,
    });
typedef $$AppMetaTableUpdateCompanionBuilder =
    AppMetaCompanion Function({
      Value<String> id,
      Value<int> updatedAt,
      Value<int?> deletedAt,
      Value<String> installId,
      Value<String> deviceInstallId,
      Value<int> installedAt,
      Value<int> rowid,
    });

class $$AppMetaTableFilterComposer
    extends Composer<_$TallyDatabase, $AppMetaTable> {
  $$AppMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceInstallId => $composableBuilder(
    column: $table.deviceInstallId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppMetaTableOrderingComposer
    extends Composer<_$TallyDatabase, $AppMetaTable> {
  $$AppMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installId => $composableBuilder(
    column: $table.installId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceInstallId => $composableBuilder(
    column: $table.deviceInstallId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetaTableAnnotationComposer
    extends Composer<_$TallyDatabase, $AppMetaTable> {
  $$AppMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get installId =>
      $composableBuilder(column: $table.installId, builder: (column) => column);

  GeneratedColumn<String> get deviceInstallId => $composableBuilder(
    column: $table.deviceInstallId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get installedAt => $composableBuilder(
    column: $table.installedAt,
    builder: (column) => column,
  );
}

class $$AppMetaTableTableManager
    extends
        RootTableManager<
          _$TallyDatabase,
          $AppMetaTable,
          AppMetaRow,
          $$AppMetaTableFilterComposer,
          $$AppMetaTableOrderingComposer,
          $$AppMetaTableAnnotationComposer,
          $$AppMetaTableCreateCompanionBuilder,
          $$AppMetaTableUpdateCompanionBuilder,
          (
            AppMetaRow,
            BaseReferences<_$TallyDatabase, $AppMetaTable, AppMetaRow>,
          ),
          AppMetaRow,
          PrefetchHooks Function()
        > {
  $$AppMetaTableTableManager(_$TallyDatabase db, $AppMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<String> installId = const Value.absent(),
                Value<String> deviceInstallId = const Value.absent(),
                Value<int> installedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                deviceInstallId: deviceInstallId,
                installedAt: installedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int updatedAt,
                Value<int?> deletedAt = const Value.absent(),
                required String installId,
                required String deviceInstallId,
                required int installedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppMetaCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                installId: installId,
                deviceInstallId: deviceInstallId,
                installedAt: installedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$TallyDatabase,
      $AppMetaTable,
      AppMetaRow,
      $$AppMetaTableFilterComposer,
      $$AppMetaTableOrderingComposer,
      $$AppMetaTableAnnotationComposer,
      $$AppMetaTableCreateCompanionBuilder,
      $$AppMetaTableUpdateCompanionBuilder,
      (AppMetaRow, BaseReferences<_$TallyDatabase, $AppMetaTable, AppMetaRow>),
      AppMetaRow,
      PrefetchHooks Function()
    >;

class $TallyDatabaseManager {
  final _$TallyDatabase _db;
  $TallyDatabaseManager(this._db);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$PlanEntriesTableTableManager get planEntries =>
      $$PlanEntriesTableTableManager(_db, _db.planEntries);
  $$WatchedAppsTableTableManager get watchedApps =>
      $$WatchedAppsTableTableManager(_db, _db.watchedApps);
  $$UsageCheckpointsTableTableManager get usageCheckpoints =>
      $$UsageCheckpointsTableTableManager(_db, _db.usageCheckpoints);
  $$DayLedgerTableTableManager get dayLedger =>
      $$DayLedgerTableTableManager(_db, _db.dayLedger);
  $$DaySpendTableTableManager get daySpend =>
      $$DaySpendTableTableManager(_db, _db.daySpend);
  $$TreatsTableTableManager get treats =>
      $$TreatsTableTableManager(_db, _db.treats);
  $$SavingsTransfersTableTableManager get savingsTransfers =>
      $$SavingsTransfersTableTableManager(_db, _db.savingsTransfers);
  $$StickerStampsTableTableManager get stickerStamps =>
      $$StickerStampsTableTableManager(_db, _db.stickerStamps);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$SuggestionHistoryTableTableManager get suggestionHistory =>
      $$SuggestionHistoryTableTableManager(_db, _db.suggestionHistory);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$AppMetaTableTableManager get appMeta =>
      $$AppMetaTableTableManager(_db, _db.appMeta);
}
