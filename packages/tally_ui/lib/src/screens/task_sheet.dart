import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme_data.dart';
import '../widgets/sticker_chip.dart';

/// What the sheet produces.
final class TaskDraft {
  const TaskDraft({
    required this.kind,
    required this.title,
    this.stickerId,
    this.estimateMinutes,
    this.habitWeekdays = const {},
  });

  final TaskKind kind;
  final String title;
  final String? stickerId;
  final int? estimateMinutes;
  final Set<int> habitWeekdays;

  bool get isValid => title.trim().isNotEmpty;
}

/// Creating or editing a task.
///
/// **One sheet for every kind.** The kind is a segmented picker inside it, not
/// four different buttons on four different screens: a user deciding between
/// "a habit" and "a thing I keep avoiding" is making one choice, and splitting
/// it across entry points is what makes task apps confusing.
///
/// Only the fields a kind actually uses appear. A one-off has no week dots and
/// a dread task has no schedule, because offering an input that does nothing is
/// worse than not offering it.
class TaskSheet extends StatefulWidget {
  const TaskSheet({
    required this.onSave,
    this.existing,
    this.initialKind = TaskKind.oneoff,
    this.onDelete,
    super.key,
  });

  final void Function(TaskDraft draft) onSave;

  /// Null when creating.
  final Task? existing;

  final TaskKind initialKind;
  final VoidCallback? onDelete;

  @override
  State<TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<TaskSheet> {
  late TaskKind _kind = widget.existing?.kind ?? widget.initialKind;
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late String? _sticker = widget.existing?.stickerId;
  late int? _estimate = widget.existing?.estimateMinutes;
  late Set<int> _weekdays = {...?widget.existing?.habitWeekdays};

  bool _pickingSticker = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _save() {
    final draft = TaskDraft(
      kind: _kind,
      title: _title.text.trim(),
      stickerId: _sticker,
      estimateMinutes: _estimate,
      habitWeekdays: _kind == TaskKind.habit ? _weekdays : const {},
    );
    if (draft.isValid) widget.onSave(draft);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final editing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        // Scrollable, and capped below the full screen height. With a keyboard
        // up on a small phone this content is taller than the space it has,
        // and a sheet that clips its own save button is unusable.
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
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
              Text(editing ? 'Edit task' : 'New task', style: text.titleLarge),
              const SizedBox(height: 16),
              _KindPicker(
                selected: _kind,
                onChanged: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: 16),
              _TitleField(controller: _title, kind: _kind),
              const SizedBox(height: 16),
              _StickerRow(
                selected: _sticker,
                expanded: _pickingSticker,
                onToggle: () =>
                    setState(() => _pickingSticker = !_pickingSticker),
                onPick: (id) => setState(() {
                  _sticker = _sticker == id ? null : id;
                  _pickingSticker = false;
                }),
              ),
              const SizedBox(height: 16),
              _EstimateRow(
                selected: _estimate,
                onPick: (minutes) => setState(
                  () => _estimate = _estimate == minutes ? null : minutes,
                ),
              ),
              // Only habits are scheduled. A dread task has no week dots because
              // the whole point of it is that it has no schedule.
              if (_kind == TaskKind.habit) ...[
                const SizedBox(height: 16),
                _WeekdayRow(
                  selected: _weekdays,
                  onToggle: (day) => setState(() {
                    _weekdays = {..._weekdays};
                    if (!_weekdays.remove(day)) _weekdays.add(day);
                  }),
                ),
              ],
              const SizedBox(height: 24),
              _SaveButton(
                label: editing ? 'Save' : 'Add task',
                enabled: _title.text.trim().isNotEmpty,
                onTap: _save,
              ),
              if (editing && widget.onDelete != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: Semantics(
                    button: true,
                    label: 'Delete task',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.selected, required this.onChanged});

  final TaskKind selected;
  final ValueChanged<TaskKind> onChanged;

  /// The words the user thinks in, not the words the model uses.
  static const labels = {
    TaskKind.habit: 'Daily',
    TaskKind.projectTask: 'Project',
    TaskKind.dread: 'Avoiding',
    TaskKind.oneoff: 'Someday',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final entry in labels.entries)
          Semantics(
            button: true,
            selected: selected == entry.key,
            label: entry.value,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onChanged(entry.key),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected == entry.key
                      ? tokens.states.solvent
                      : tokens.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  entry.value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selected == entry.key ? tokens.bg : tokens.inkMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TitleField extends StatelessWidget {
  const _TitleField({required this.controller, required this.kind});

  final TextEditingController controller;
  final TaskKind kind;

  /// A hint per kind, written as the user would say it out loud.
  static const hints = {
    TaskKind.habit: 'Piano, 20 minutes',
    TaskKind.projectTask: 'Write the introduction',
    TaskKind.dread: 'Clean the flat',
    TaskKind.oneoff: 'Book the dentist',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TextField(
      controller: controller,
      autofocus: true,
      textCapitalization: TextCapitalization.sentences,
      style: Theme.of(context).textTheme.bodyLarge,
      cursorColor: tokens.states.solvent,
      decoration: InputDecoration(
        hintText: hints[kind],
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
      onChanged: (_) {
        // Rebuilds the sheet so the save button enables as soon as there is a
        // title, rather than only after the field loses focus.
        (context as Element).markNeedsBuild();
      },
    );
  }
}

class _StickerRow extends StatelessWidget {
  const _StickerRow({
    required this.selected,
    required this.expanded,
    required this.onToggle,
    required this.onPick,
  });

  final String? selected;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('STICKER', style: text.labelSmall),
            const Spacer(),
            Semantics(
              button: true,
              label: expanded ? 'Close sticker picker' : 'Choose a sticker',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onToggle,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  height: 44,
                  child: Row(
                    children: [
                      if (selected != null) StickerChip(stickerId: selected!),
                      const SizedBox(width: 8),
                      Text(
                        selected == null ? 'Choose' : 'Change',
                        style: text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (expanded)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final sticker in StickerCatalog.base)
                Semantics(
                  button: true,
                  label: sticker.id,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onPick(sticker.id),
                    behavior: HitTestBehavior.opaque,
                    child: StickerChip(stickerId: sticker.id, size: 38),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _EstimateRow extends StatelessWidget {
  const _EstimateRow({required this.selected, required this.onPick});

  final int? selected;
  final ValueChanged<int> onPick;

  /// Every option is at or above the five minute earning floor, so the sheet
  /// cannot produce a task whose own estimate could never earn.
  static const options = [5, 10, 15, 20, 30, 45, 60];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HOW LONG', style: text.labelSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final minutes in options)
              Semantics(
                button: true,
                selected: selected == minutes,
                label: '$minutes minutes',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => onPick(minutes),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 40,
                    constraints: const BoxConstraints(minWidth: 52),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected == minutes
                          ? tokens.states.solvent
                          : tokens.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${minutes}m',
                      style: text.bodyLarge?.copyWith(
                        color: selected == minutes
                            ? tokens.bg
                            : tokens.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.selected, required this.onToggle});

  final Set<int> selected;
  final ValueChanged<int> onToggle;

  static const names = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const full = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('WHICH DAYS', style: text.labelSmall),
            const SizedBox(width: 8),
            // An empty selection is every day rather than no days, so the
            // control has no state that means "never".
            if (selected.isEmpty) Text('every day', style: text.labelMedium),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var day = 1; day <= 7; day++) ...[
              Expanded(
                child: Semantics(
                  button: true,
                  selected: selected.contains(day),
                  label: full[day - 1],
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onToggle(day),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected.contains(day)
                            ? tokens.states.solvent
                            : tokens.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        names[day - 1],
                        style: text.bodyLarge?.copyWith(
                          color: selected.contains(day)
                              ? tokens.bg
                              : tokens.inkMuted,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (day != 7) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: enabled ? tokens.states.solvent : tokens.surface,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: enabled ? tokens.bg : tokens.inkFaint,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
