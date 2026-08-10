import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme_data.dart';
import '../widgets/balance_strip.dart';
import '../widgets/task_row.dart';

/// Everything the Today screen draws, assembled by the caller.
///
/// A plain value rather than a live controller, so the screen is a pure
/// function of it and golden tests can pin any state without a database.
final class TodayScreenModel {
  const TodayScreenModel({
    required this.view,
    required this.spendableSeconds,
    required this.solvencyStreak,
    required this.dateLabel,
    this.suggestion,
    this.graceNotice,
  });

  final TodayView view;
  final int spendableSeconds;
  final int solvencyStreak;

  /// Written out, e.g. "Tue 11 August". Formatted by the caller so this package
  /// carries no locale data.
  final String dateLabel;

  /// The day's single library suggestion, or null when nothing is eligible.
  final LibraryItem? suggestion;

  /// Shown in place of the suggestion when the day went negative.
  ///
  /// Exists because a nudge the OS refused to deliver still has to reach the
  /// user, and this is where it lands on next open.
  final String? graceNotice;
}

/// Today. **The front door.**
///
/// Balance strip, the date, the plan in the user's order, and one suggestion.
/// The header states planned minutes and nothing else: **no cap, no warning, no
/// colour change.** The number is the warning, and that is this app's whole
/// tone.
class TodayScreen extends StatelessWidget {
  const TodayScreen({
    required this.model,
    this.onToggle,
    this.onStartFocus,
    this.onReorder,
    this.onOpenBalance,
    this.onOpenPool,
    this.onAcceptSuggestion,
    this.onDismissSuggestion,
    this.onAcceptHabit,
    this.onStartSession,
    super.key,
  });

  final TodayScreenModel model;
  final void Function(PlanEntry entry)? onToggle;
  final void Function(PlanEntry entry)? onStartFocus;
  final void Function(int from, int to)? onReorder;
  final VoidCallback? onOpenBalance;
  final VoidCallback? onOpenPool;
  final void Function(LibraryItem item)? onAcceptSuggestion;
  final void Function(LibraryItem item)? onDismissSuggestion;
  final void Function(Task habit)? onAcceptHabit;
  final VoidCallback? onStartSession;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final view = model.view;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BalanceStrip(
              spendableSeconds: model.spendableSeconds,
              solvencyStreak: model.solvencyStreak,
              onTap: onOpenBalance,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              // Wrap rather than Row: at large text sizes the date and the
              // planned total do not fit on one line, and a Spacer between two
              // unflexible Texts overflows rather than yielding. This drops the
              // total to a second line instead, which is the right answer for
              // a header whose whole job is to be readable.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 4,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          model.dateLabel.toUpperCase(),
                          style: text.labelSmall
                              ?.copyWith(color: tokens.inkMuted),
                        ),
                        // The only feedback on an overloaded day. Stated,
                        // never coloured, never capped.
                        Text(
                          '${view.plannedMinutes} min planned',
                          style: text.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: view.isEmpty && view.offeredHabits.isEmpty
                  ? _EmptyToday(onOpenPool: onOpenPool)
                  : _PlanList(
                      model: model,
                      onToggle: onToggle,
                      onStartFocus: onStartFocus,
                      onReorder: onReorder,
                      onOpenPool: onOpenPool,
                      onAcceptSuggestion: onAcceptSuggestion,
                      onDismissSuggestion: onDismissSuggestion,
                      onAcceptHabit: onAcceptHabit,
                    ),
            ),
            _StartFocusButton(
              enabled: !view.isEmpty,
              onTap: onStartSession,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _PlanList extends StatelessWidget {
  const _PlanList({
    required this.model,
    this.onToggle,
    this.onStartFocus,
    this.onReorder,
    this.onOpenPool,
    this.onAcceptSuggestion,
    this.onDismissSuggestion,
    this.onAcceptHabit,
  });

  final TodayScreenModel model;
  final void Function(PlanEntry entry)? onToggle;
  final void Function(PlanEntry entry)? onStartFocus;
  final void Function(int from, int to)? onReorder;
  final VoidCallback? onOpenPool;
  final void Function(LibraryItem item)? onAcceptSuggestion;
  final void Function(LibraryItem item)? onDismissSuggestion;
  final void Function(Task habit)? onAcceptHabit;

  @override
  Widget build(BuildContext context) {
    final view = model.view;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: view.rows.length,
          // onReorderItem rather than onReorder: it reports the destination
          // as a final position, where the older callback reported an
          // insertion index that runs one high when moving down. The planner
          // takes a final position, so this removes an off-by-one that would
          // only show when dragging downwards.
          onReorderItem: (from, to) => onReorder?.call(from, to),
          itemBuilder: (context, index) {
            final row = view.rows[index];
            return Padding(
              key: ValueKey(row.entry.id),
              padding: const EdgeInsets.only(bottom: 6),
              child: ReorderableDelayedDragStartListener(
                index: index,
                child: TaskRow(
                  title: row.task.title,
                  done: row.isDone,
                  stickerId: row.stickerId,
                  estimateMinutes: row.task.estimateMinutes,
                  subtitle: row.avoidedDays > 0
                      ? 'avoided ${row.avoidedDays} days'
                      : null,
                  onToggle: () => onToggle?.call(row.entry),
                  onStartFocus: () => onStartFocus?.call(row.entry),
                ),
              ),
            );
          },
        ),
        for (final habit in view.offeredHabits)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _OfferedHabit(
              habit: habit,
              onAccept: () => onAcceptHabit?.call(habit),
            ),
          ),
        _AddFromList(onTap: onOpenPool),
        if (model.graceNotice != null)
          _Notice(text: model.graceNotice!)
        else if (model.suggestion != null)
          _Suggestion(
            item: model.suggestion!,
            onAccept: () => onAcceptSuggestion?.call(model.suggestion!),
            onDismiss: () => onDismissSuggestion?.call(model.suggestion!),
          ),
      ],
    );
  }
}

/// A habit due today.
///
/// **Offered, never auto-added.** An app that fills your day for you is an app
/// you stop trusting by Thursday, so this is a distinct row shape that takes
/// one tap to accept.
class _OfferedHabit extends StatelessWidget {
  const _OfferedHabit({required this.habit, required this.onAccept});

  final Task habit;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Add ${habit.title} to today',
      // The label fully describes the control, and without this the Text
      // children produce their own nodes that compete with it, leaving the
      // button unfindable to a screen reader looking for one action.
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onAccept,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tokens.surfaceStrong),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${habit.title} · due today',
                  style: text.bodyLarge?.copyWith(color: tokens.inkMuted),
                ),
              ),
              Text(
                'Add',
                style: text.bodyLarge?.copyWith(color: tokens.states.solvent),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddFromList extends StatelessWidget {
  const _AddFromList({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: 'Add tasks from your list',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            '+ from my list',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: tokens.inkFaint,
                ),
          ),
        ),
      ),
    );
  }
}

/// The day's single library suggestion.
class _Suggestion extends StatelessWidget {
  const _Suggestion({
    required this.item,
    required this.onAccept,
    required this.onDismiss,
  });

  final LibraryItem item;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TODAY’S SUGGESTION', style: text.labelSmall),
          const SizedBox(height: 6),
          Text(
            '${item.title} · ${item.minutes}m'
            '${item.phoneDown ? ' · phone down, 1.5x' : ''}',
            style: text.bodyLarge,
          ),
          const SizedBox(height: 4),
          // The reason states a mechanism. The library ships zero quotes and
          // this is where that shows.
          Text(item.why, style: text.bodyMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniButton(label: 'Add', onTap: onAccept, primary: true),
              const SizedBox(width: 8),
              _MiniButton(label: 'Not now', onTap: onDismiss),
            ],
          ),
        ],
      ),
    );
  }
}

/// What a notification would have said, shown on next open.
///
/// Settled decision 9: with notifications denied the app stays fully usable and
/// the grace warning becomes an in-app banner. Also where a nudge held back by
/// quiet hours or the daily cap lands.
class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: primary ? tokens.states.solvent : tokens.surfaceStrong,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: primary ? tokens.bg : tokens.inkMuted,
                    fontSize: 13,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The empty state.
///
/// **An empty day is not a finished day**, and the copy must not congratulate
/// or scold. It states what the screen is for and offers the one action.
class _EmptyToday extends StatelessWidget {
  const _EmptyToday({this.onOpenPool});

  final VoidCallback? onOpenPool;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nothing planned',
              style: text.titleLarge?.copyWith(color: tokens.inkMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a few things you mean to do today. '
              'They do not have to be big ones.',
              style: text.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _MiniButton(
              label: 'From my list',
              onTap: onOpenPool ?? () {},
              primary: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StartFocusButton extends StatelessWidget {
  const _StartFocusButton({required this.enabled, this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Semantics(
        button: true,
        label: 'Start focus',
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: enabled ? tokens.states.solvent : const Color(0x00000000),
              border: enabled
                  ? null
                  : Border.all(color: tokens.surfaceStrong),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Start focus',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: enabled ? tokens.bg : tokens.inkFaint,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
