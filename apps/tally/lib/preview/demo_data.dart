import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

/// A plausible Tuesday, built from the real engines.
///
/// **Nothing here is mocked at the UI layer.** The plan is assembled by
/// `TodayPlanner`, the suggestion is picked by the real `SuggestionPicker`, and
/// the numbers obey the real ledger rules. The preview is therefore a test of
/// the whole stack's output and not only of the drawing.
final class DemoDay {
  const DemoDay._();

  static const dayKey = '2026-08-11'; // a Tuesday
  static final now = DateTime.utc(2026, 8, 11, 9, 41);

  static const installId = '018f2c00-aaaa-7000-8000-000000000001';

  static final tasks = <Task>[
    Task(
      id: 'surface',
      kind: TaskKind.oneoff,
      title: 'Clear one surface',
      createdAt: DateTime.utc(2026, 8, 10),
      stickerId: 'cleaning',
      estimateMinutes: 10,
    ),
    Task(
      id: 'gym',
      kind: TaskKind.habit,
      title: 'Gym',
      createdAt: DateTime.utc(2026, 7, 1),
      stickerId: 'gym',
      estimateMinutes: 45,
      habitWeekdays: const {1, 2, 5},
    ),
    Task(
      id: 'sub',
      kind: TaskKind.oneoff,
      title: 'Cancel one subscription',
      createdAt: DateTime.utc(2026, 8, 5),
      stickerId: 'money',
      estimateMinutes: 10,
    ),
    Task(
      id: 'flat',
      kind: TaskKind.dread,
      title: 'Clean the flat',
      createdAt: DateTime.utc(2026, 7, 8),
      stickerId: 'cleaning',
      estimateMinutes: 30,
    ),
    // Due today and deliberately left unplanned, so the offered-habit row is
    // visible in the preview.
    Task(
      id: 'piano',
      kind: TaskKind.habit,
      title: 'Piano',
      createdAt: DateTime.utc(2026, 6, 1),
      stickerId: 'music',
      estimateMinutes: 20,
      habitWeekdays: const {2, 4},
    ),
  ];

  static const planner = TodayPlanner();

  /// The plan, with one row already ticked.
  static List<PlanEntry> plan() {
    var entries = planner.addToDay(
      dayKey: dayKey,
      plan: const [],
      taskIds: ['surface', 'gym', 'sub', 'flat'],
    );
    entries = planner
        .complete(
          plan: entries,
          entryId: entries[2].id,
          tasks: tasks,
          at: now,
          dayKey: dayKey,
        )
        .plan;
    return entries;
  }

  /// The day's suggestion, from the real picker over the real library.
  static LibraryItem? suggestion(List<LibraryItem> library) =>
      const SuggestionPicker().suggestionFor(
        dayKey: dayKey,
        installId: installId,
        library: library,
        addedItemIds: {for (final t in tasks) t.id},
      );
}

/// The balance states the preview can be pinned to.
enum DemoState {
  solvent('Solvent', 2520, 6),
  low('Running low', 420, 6),
  borrowing('Borrowing', -1080, 0),
  empty('Nothing planned', 1800, 3);

  const DemoState(this.label, this.spendableSeconds, this.streak);

  final String label;
  final int spendableSeconds;
  final int streak;

  /// Shown instead of the suggestion once the day has gone negative.
  String? get notice => this == DemoState.borrowing
      ? 'Grace used at 21:38. Every minute since has been −1. '
          'Debt stops at −60, and tomorrow’s allowance clears it before it '
          'fills your balance.'
      : null;
}

/// Sanity: the demo balance and the state colour agree.
BalanceState stateOf(DemoState demo) =>
    BalanceState.forSeconds(demo.spendableSeconds);
