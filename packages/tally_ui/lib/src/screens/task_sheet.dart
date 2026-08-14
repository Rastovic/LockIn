import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme_data.dart';
import '../widgets/sticker_chip.dart';

/// What the sheet produces.
final class TaskDraft {
  const TaskDraft({
    required this.kind,
    required this.title,
    this.note,
    this.stickerId,
    this.estimateMinutes,
    this.projectId,
    this.habitWeekdays = const {},
  });

  final TaskKind kind;
  final String title;

  /// The longer version, or null. Nothing in the ledger reads it.
  final String? note;

  final String? stickerId;
  final int? estimateMinutes;

  /// The project this task belongs to, when it was created inside one.
  final String? projectId;

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
    this.projectId,
    this.projectName,
    super.key,
  });

  final void Function(TaskDraft draft) onSave;

  /// Null when creating.
  final Task? existing;

  final TaskKind initialKind;
  final VoidCallback? onDelete;

  /// Set when the sheet was opened from inside a project.
  ///
  /// The kind is then settled and the picker is hidden: someone tapping "add
  /// a task" under a project has already said what they are making, and
  /// offering to turn it into a habit is offering to lose it.
  final String? projectId;
  final String? projectName;

  @override
  State<TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<TaskSheet> {
  late TaskKind _kind = widget.existing?.kind ??
      (widget.projectId != null ? TaskKind.projectTask : widget.initialKind);
  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late String? _sticker = widget.existing?.stickerId;
  late int? _estimate = widget.existing?.estimateMinutes;
  late final _note = TextEditingController(text: widget.existing?.note ?? '');

  @override
  void initState() {
    super.initState();
    // The save button is disabled until there is a title, so the sheet itself
    // has to rebuild as the title is typed. This used to be a markNeedsBuild
    // on the field's own element, which rebuilt the field and not the button
    // above it - it happened to work only while the field was the whole
    // widget, and stopped the moment the field grew a label.
    _title.addListener(_onTitleChanged);
  }

  void _onTitleChanged() {
    final canSave = _title.text.trim().isNotEmpty;
    if (canSave != _canSave) setState(() => _canSave = canSave);
  }

  late bool _canSave = (widget.existing?.title ?? '').trim().isNotEmpty;
  late Set<int> _weekdays = {...?widget.existing?.habitWeekdays};

  bool _pickingSticker = false;

  @override
  void dispose() {
    _title.removeListener(_onTitleChanged);
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final draft = TaskDraft(
      kind: _kind,
      title: _title.text.trim(),
      stickerId: _sticker,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      // Dropped rather than kept hidden: switching a task to quick and back
      // should not resurrect an estimate the user can no longer see.
      estimateMinutes: _kind == TaskKind.quick ? null : _estimate,
      projectId: _kind == TaskKind.projectTask ? widget.projectId : null,
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
              if (widget.projectName == null) ...[
                _KindPicker(
                  selected: _kind,
                  onChanged: (kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Text('IN PROJECT', style: text.labelSmall),
                const SizedBox(height: 6),
                Text(widget.projectName!, style: text.bodyLarge),
                const SizedBox(height: 16),
              ],
              _TitleField(controller: _title, kind: _kind),
              const SizedBox(height: 10),
              _NoteField(controller: _note, kind: _kind),
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
              // A quick task has no timer. Offering one would invite an
              // estimate on something that takes two seconds, and every
              // estimate the wheel can produce is longer than the task.
              if (_kind != TaskKind.quick) ...[
                const SizedBox(height: 16),
                _EstimateRow(
                  selected: _estimate,
                  onPick: (minutes) => setState(() => _estimate = minutes),
                ),
              ],
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
                enabled: _canSave,
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

/// The kind, as a dropdown.
///
/// Was four chips. They read as a filter rather than a field, and they cost a
/// full row of the sheet to show three options nobody was choosing between:
/// the kind is nearly always already correct, because it is inherited from
/// wherever "new task" was tapped. A closed control states that answer in one
/// line and gets out of the way, which is what a field that is usually right
/// should do.
class _KindPicker extends StatelessWidget {
  const _KindPicker({required this.selected, required this.onChanged});

  final TaskKind selected;
  final ValueChanged<TaskKind> onChanged;

  /// The words the user thinks in, not the words the model uses.
  static const labels = {
    TaskKind.habit: 'Daily',
    TaskKind.quick: 'Quick',
    TaskKind.projectTask: 'Project',
    TaskKind.dread: 'Avoiding',
    TaskKind.oneoff: 'Someday',
  };

  /// What each kind actually does, since the label alone does not say.
  static const detail = {
    TaskKind.habit: 'on a rhythm, carries a streak',
    TaskKind.projectTask: 'part of something bigger',
    TaskKind.dread: 'counts the days you put it off',
    TaskKind.quick: 'a minute or less, no timer',
    TaskKind.oneoff: 'kept until you plan it',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('KIND', style: text.labelSmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TaskKind>(
              value: selected,
              isExpanded: true,
              // Two lines per item. The default 48 clips the detail line by
              // three pixels, which shows up as an overflow stripe.
              itemHeight: 58,
              borderRadius: BorderRadius.circular(14),
              dropdownColor: Color.alphaBlend(tokens.surfaceStrong, tokens.bg),
              icon: Icon(Icons.expand_more, color: tokens.inkFaint, size: 20),
              style: text.bodyLarge?.copyWith(color: tokens.ink),
              onChanged: (kind) => kind == null ? null : onChanged(kind),
              // The closed field shows the label alone. The detail belongs in
              // the open list, where a choice is actually being made.
              selectedItemBuilder: (context) => [
                for (final entry in labels.entries)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(entry.value, style: text.bodyLarge),
                  ),
              ],
              items: [
                for (final entry in labels.entries)
                  DropdownMenuItem(
                    value: entry.key,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.value, style: text.bodyLarge),
                        Text(
                          detail[entry.key]!,
                          style: text.labelMedium
                              ?.copyWith(color: tokens.inkFaint),
                        ),
                      ],
                    ),
                  ),
              ],
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
  ///
  /// These are examples of a **title**, and were read as an instruction to
  /// write a description - "Write the introduction" looked like a prompt
  /// rather than a sample task. With a labelled description field underneath,
  /// the hint has somewhere to be a hint about.
  static const hints = {
    TaskKind.habit: 'Piano, 20 minutes',
    TaskKind.projectTask: 'Write the introduction',
    TaskKind.dread: 'Clean the flat',
    TaskKind.quick: 'Take supplements',
    TaskKind.oneoff: 'Book the dentist',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TITLE', style: text.labelSmall),
        const SizedBox(height: 8),
        TextField(
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
        ),
      ],
    );
  }
}

/// The longer version, under the title.
///
/// Four lines tall rather than one, because a field the height of a title
/// invites a title-length answer, and this one exists for the sentences that
/// did not fit. Optional everywhere, and nothing reads it: it holds what the
/// task involves or why it has been sitting there, and no part of the ledger
/// is allowed to care.
class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller, required this.kind});

  final TextEditingController controller;
  final TaskKind kind;

  static const hints = {
    TaskKind.habit: 'Scales first, then the piece.',
    TaskKind.projectTask: 'Two paragraphs on why the study was run.',
    TaskKind.dread: 'Kitchen and the pile by the door.',
    TaskKind.quick: 'The vitamin D and the magnesium.',
    TaskKind.oneoff: 'The one on the high street, they open at nine.',
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('DESCRIPTION', style: text.labelSmall),
            const SizedBox(width: 6),
            Text(
              'optional',
              style: text.labelSmall?.copyWith(color: tokens.inkFaint),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 4,
          maxLines: 6,
          textCapitalization: TextCapitalization.sentences,
          keyboardType: TextInputType.multiline,
          style: text.bodyLarge,
          cursorColor: tokens.states.solvent,
          decoration: InputDecoration(
            hintText: hints[kind],
            hintStyle: text.bodyMedium,
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
        ),
      ],
    );
  }
}

/// Choosing a sticker.
///
/// Was a small "STICKER" label with a quiet "Choose" pushed to the far right,
/// which read as two unrelated things and disappeared into the sheet. It is
/// now one control that says what it does, at the same size as before: the
/// problem was never that it was too small, it was that nothing marked it as
/// something you could press.
///
/// It carries the accent only while **nothing is chosen**. Once a sticker is
/// picked the sticker itself is the colour on that row, and a tinted button
/// beside it would compete with the thing it just set.
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
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final empty = selected == null;
    final accent = tokens.states.solvent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: expanded,
          label: empty ? 'Choose a sticker' : 'Change sticker',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: empty
                    ? accent.withValues(alpha: 0.14)
                    : tokens.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: empty ? accent.withValues(alpha: 0.5) : tokens.surface,
                ),
              ),
              child: Row(
                children: [
                  if (!empty) ...[
                    StickerChip(stickerId: selected!),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    empty ? 'Choose a sticker' : 'Change sticker',
                    style: text.bodyLarge?.copyWith(
                      color: empty ? accent : tokens.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: empty ? accent : tokens.inkFaint,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Wrap(
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
          ),
      ],
    );
  }
}

/// What the estimate wheel offers.
///
/// Public so a test can assert the floor rather than restating the list, which
/// is how a list and its rule drift apart.
final class EstimateOptions {
  const EstimateOptions._();

  /// **Nothing below the five minute earning floor is offered.** An estimate
  /// under it would describe a task whose own plan could never earn a minute.
  static const all = <int>[
    5, 10, 15, 20, 25, 30, 40, 45, 50, 60, 75, 90, 105, 120,
  ];
}

/// How long, as a wheel.
///
/// Was a row of chips at 5, 10, 15, 20, 30, 45 and 60. The wheel covers the
/// same ground plus everything up to two hours without a row of chips that
/// wraps onto three lines, and reads as one continuous quantity rather than
/// seven unrelated buttons.
///
/// **Nothing below five minutes is offered**, including "none": five is the
/// earning floor, so a shorter estimate would describe a task whose own plan
/// could never earn a minute. Clearing it is a separate, explicit tap.
class _EstimateRow extends StatefulWidget {
  const _EstimateRow({required this.selected, required this.onPick});

  final int? selected;

  /// Null clears the estimate.
  final ValueChanged<int?> onPick;

  @override
  State<_EstimateRow> createState() => _EstimateRowState();
}

class _EstimateRowState extends State<_EstimateRow> {
  static const options = EstimateOptions.all;

  /// Owned by the state, not built in [build].
  ///
  /// It was built inline, which meant every spin rebuilt the sheet, which
  /// built a fresh controller, which reset the wheel mid-gesture. The wheel
  /// looked like it worked by hand - a flick lands somewhere - and reliably
  /// dropped the value under a precise drag.
  late final _controller = FixedExtentScrollController(
    // Rests on 15 when nothing is chosen: a middling estimate rather than the
    // shortest one, so the wheel does not nudge every task towards five.
    initialItem: widget.selected == null
        ? options.indexOf(15)
        : options.indexOf(widget.selected!),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_EstimateRow old) {
    super.didUpdateWidget(old);
    // Only when something outside the wheel changed the value, such as Clear.
    final target = widget.selected;
    if (target != null &&
        _controller.hasClients &&
        _controller.selectedItem != options.indexOf(target)) {
      _controller.jumpToItem(options.indexOf(target));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final selected = widget.selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('HOW LONG', style: text.labelSmall),
            const Spacer(),
            if (selected != null)
              Semantics(
                button: true,
                label: 'Clear estimate',
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => widget.onPick(null),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    child: Text(
                      'Clear',
                      style: text.labelMedium?.copyWith(color: tokens.inkMuted),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 116,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // The selection sits still and the numbers move through it,
              // which is what makes a wheel readable at a glance.
              Container(
                height: 38,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: tokens.surfaceStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Semantics(
                label: selected == null
                    ? 'How long, nothing chosen'
                    : 'How long, $selected minutes',
                excludeSemantics: true,
                child: ListWheelScrollView.useDelegate(
                  itemExtent: 38,
                  diameterRatio: 1.6,
                  physics: const FixedExtentScrollPhysics(),
                  controller: _controller,
                  onSelectedItemChanged: (i) => widget.onPick(options[i]),
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: options.length,
                    builder: (context, i) => Center(
                      child: Text(
                        '${options[i]} min',
                        style: text.bodyLarge?.copyWith(
                          color: options[i] == selected
                              ? tokens.ink
                              : tokens.inkFaint,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
