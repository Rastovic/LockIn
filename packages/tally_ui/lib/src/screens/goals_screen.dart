import 'package:flutter/material.dart';

import '../theme/tally_theme_data.dart';

/// Year or life.
enum GoalScope {
  year('This year'),
  life('Someday');

  const GoalScope(this.label);

  final String label;
}

/// A goal.
///
/// **Not a task, and the type says so.** No estimate, no schedule, no sticker
/// requirement and no completion that earns anything. The only thing it can do
/// is name a project, which is where it earns its keep.
final class Goal {
  const Goal({
    required this.id,
    required this.scope,
    required this.title,
    this.note,
    this.linkedProjectTitle,
    this.linkedSessions = 0,
    this.linkedSeconds = 0,
    this.achievedAt,
  });

  final String id;
  final GoalScope scope;
  final String title;
  final String? note;

  final String? linkedProjectTitle;
  final int linkedSessions;
  final int linkedSeconds;

  final DateTime? achievedAt;

  bool get isAchieved => achievedAt != null;
}

/// Year goals and life goals.
///
/// The least featured screen in the app, on purpose. **No dates, no reminders,
/// no progress bars, and no path into a day.** Most life-goal features go
/// unused by week two, so this one is built cheap enough that it not mattering
/// does not matter.
///
/// What it is not: a task list. A goal has a different card shape, no checkbox
/// and no play button, because the moment a goal can be ticked it becomes
/// another thing to fail at.
class GoalsScreen extends StatelessWidget {
  const GoalsScreen({
    required this.goals,
    this.onAdd,
    this.onEdit,
    this.onAchieve,
    this.onBack,
    super.key,
  });

  final List<Goal> goals;
  final void Function(GoalScope scope)? onAdd;
  final void Function(Goal goal)? onEdit;
  final void Function(Goal goal)? onAchieve;
  final VoidCallback? onBack;

  List<Goal> _of(GoalScope scope) =>
      goals.where((g) => g.scope == scope && !g.isAchieved).toList();

  List<Goal> get _achieved => goals.where((g) => g.isAchieved).toList();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 4),
              child: Row(
                children: [
                  if (onBack != null)
                    Semantics(
                      button: true,
                      label: 'Back',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onBack,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: tokens.inkMuted,
                          ),
                        ),
                      ),
                    ),
                  Text('Goals', style: text.headlineMedium),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Text(
                    // Says what the screen is for, and what it deliberately
                    // will not do.
                    'Things you are working towards. They are never added to a '
                    'day and they never earn anything.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 22),
                  for (final scope in GoalScope.values) ...[
                    Text(scope.label.toUpperCase(), style: text.labelSmall),
                    const SizedBox(height: 10),
                    for (final goal in _of(scope))
                      _GoalCard(
                        goal: goal,
                        onTap: () => onEdit?.call(goal),
                        onAchieve: () => onAchieve?.call(goal),
                      ),
                    _AddGoal(
                      label: scope == GoalScope.year
                          ? 'Add something for this year'
                          : 'Add something for someday',
                      onTap: () => onAdd?.call(scope),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_achieved.isNotEmpty) ...[
                    Text('DONE', style: text.labelSmall),
                    const SizedBox(height: 10),
                    for (final goal in _achieved)
                      _AchievedRow(goal: goal),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onAchieve,
  });

  final Goal goal;
  final VoidCallback onTap;
  final VoidCallback onAchieve;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: goal.title,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          decoration: BoxDecoration(
            // A different shape from a task row on purpose: no card fill, an
            // outline instead, so the two never read as the same kind of thing.
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.surfaceStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(goal.title, style: text.titleLarge)),
                  Semantics(
                    button: true,
                    label: 'Mark ${goal.title} achieved',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: onAchieve,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.check,
                          size: 18,
                          color: tokens.inkFaint,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (goal.note != null) ...[
                const SizedBox(height: 4),
                Text(goal.note!, style: text.bodyMedium),
              ],
              // The one place a goal earns its keep: a linked project turns it
              // from a wish into something with hours behind it.
              if (goal.linkedProjectTitle != null && goal.linkedSessions > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '${goal.linkedProjectTitle}: ${goal.linkedSessions} '
                    'sessions, ${(goal.linkedSeconds / 3600).floor()} hours',
                    style: text.labelMedium?.copyWith(
                      color: tokens.states.solvent,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievedRow extends StatelessWidget {
  const _AchievedRow({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final when = goal.achievedAt!.toLocal();

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              goal.title,
              style: text.bodyLarge?.copyWith(color: tokens.inkMuted),
            ),
          ),
          Text(
            '${when.day}/${when.month}/${when.year}',
            style: text.labelMedium,
          ),
        ],
      ),
    );
  }
}

class _AddGoal extends StatelessWidget {
  const _AddGoal({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: 44,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '+ $label',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: tokens.inkFaint,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Creating or editing a goal.
///
/// Title, an optional note, and nothing else. Every field this sheet does not
/// have is a deliberate omission.
class GoalSheet extends StatefulWidget {
  const GoalSheet({
    required this.scope,
    required this.onSave,
    this.existing,
    this.onDelete,
    super.key,
  });

  final GoalScope scope;
  final void Function(String title, String? note) onSave;
  final Goal? existing;
  final VoidCallback? onDelete;

  @override
  State<GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends State<GoalSheet> {
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final valid = _title.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: tokens.surfaceStrong,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                widget.existing == null
                    ? (widget.scope == GoalScope.year
                        ? 'For this year'
                        : 'For someday')
                    : 'Edit goal',
                style: text.titleLarge,
              ),
              const SizedBox(height: 16),
              _Field(
                controller: _title,
                hint: widget.scope == GoalScope.year
                    ? 'Finish the thesis'
                    : 'Learn to sail',
                autofocus: true,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 10),
              _Field(
                controller: _note,
                hint: 'A note, if you want one',
                maxLines: 3,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 20),
              Semantics(
                button: true,
                enabled: valid,
                label: 'Save goal',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: valid
                      ? () => widget.onSave(
                            _title.text.trim(),
                            _note.text.trim().isEmpty
                                ? null
                                : _note.text.trim(),
                          )
                      : null,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: valid ? tokens.states.solvent : tokens.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Save',
                      style: text.bodyLarge?.copyWith(
                        color: valid ? tokens.bg : tokens.inkFaint,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(height: 6),
                Center(
                  child: Semantics(
                    button: true,
                    label: 'Delete goal',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: Text(
                            'Delete',
                            style: text.bodyLarge?.copyWith(
                              color: tokens.states.borrowing,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.autofocus = false,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final bool autofocus;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      textCapitalization: TextCapitalization.sentences,
      style: Theme.of(context).textTheme.bodyLarge,
      cursorColor: tokens.states.solvent,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium,
        filled: true,
        fillColor: tokens.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}
