import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme_data.dart';
import '../widgets/sticker_chip.dart';

/// The pool: everything created and not yet planned into today.
///
/// Search, filter by sticker, tick several, add them at once. Multi-select
/// because planning a day is one sitting: closing and reopening a sheet per
/// task turns a two minute job into a chore.
class PoolSheet extends StatefulWidget {
  const PoolSheet({
    required this.available,
    required this.onAdd,
    this.now,
    super.key,
  });

  /// Tasks not already in today's plan.
  final List<Task> available;

  final void Function(List<String> taskIds) onAdd;

  /// For the avoided-days line. Defaults to now.
  final DateTime? now;

  @override
  State<PoolSheet> createState() => _PoolSheetState();
}

class _PoolSheetState extends State<PoolSheet> {
  final _selected = <String>{};
  final _search = TextEditingController();
  String? _stickerFilter;

  static const _planner = TodayPlanner();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Task> get _visible {
    final query = _search.text.trim().toLowerCase();
    return [
      for (final task in widget.available)
        if (!task.isArchived)
          if (_stickerFilter == null || task.stickerId == _stickerFilter)
            if (query.isEmpty || task.title.toLowerCase().contains(query))
              task,
    ];
  }

  /// Only stickers actually in use, so the filter row is never a wall of
  /// options that all return nothing.
  List<String> get _stickersInUse {
    final used = <String>{};
    for (final task in widget.available) {
      if (task.stickerId != null) used.add(task.stickerId!);
    }
    return used.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final visible = _visible;
    final now = widget.now ?? DateTime.now().toUtc();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: tokens.surfaceStrong,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('From my list', style: text.titleLarge),
                const Spacer(),
                Text('${widget.available.length} waiting',
                    style: text.labelMedium),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              style: text.bodyLarge,
              cursorColor: tokens.states.solvent,
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: text.bodyMedium,
                prefixIcon: Icon(Icons.search, size: 18, color: tokens.inkFaint),
                filled: true,
                fillColor: tokens.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_stickersInUse.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final sticker in _stickersInUse) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      child: Semantics(
                        button: true,
                        selected: _stickerFilter == sticker,
                        label: 'Filter by $sticker',
                        excludeSemantics: true,
                        child: GestureDetector(
                          onTap: () => setState(
                            () => _stickerFilter =
                                _stickerFilter == sticker ? null : sticker,
                          ),
                          child: Opacity(
                            opacity: _stickerFilter == null ||
                                    _stickerFilter == sticker
                                ? 1
                                : 0.35,
                            child: StickerChip(stickerId: sticker, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          Flexible(
            child: visible.isEmpty
                ? _Empty(searching: _search.text.trim().isNotEmpty)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    itemCount: visible.length,
                    itemBuilder: (context, index) {
                      final task = visible[index];
                      final avoided = _planner.avoidedDaysFor(task, now: now);
                      return _PoolRow(
                        task: task,
                        selected: _selected.contains(task.id),
                        avoidedDays: avoided,
                        onTap: () => setState(() {
                          if (!_selected.remove(task.id)) {
                            _selected.add(task.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Semantics(
              button: true,
              enabled: _selected.isNotEmpty,
              label: _addLabel,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: _selected.isEmpty
                    ? null
                    : () => widget.onAdd(_selected.toList()),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selected.isEmpty
                        ? tokens.surface
                        : tokens.states.solvent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _addLabel,
                    style: text.bodyLarge?.copyWith(
                      color: _selected.isEmpty ? tokens.inkFaint : tokens.bg,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The button says how many, so the tap is never a guess.
  String get _addLabel => switch (_selected.length) {
        0 => 'Pick something to add',
        1 => 'Add 1 task',
        final n => 'Add $n tasks',
      };
}

class _PoolRow extends StatelessWidget {
  const _PoolRow({
    required this.task,
    required this.selected,
    required this.avoidedDays,
    required this.onTap,
  });

  final Task task;
  final bool selected;
  final int avoidedDays;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: task.title,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(14),
            border: selected
                ? Border.all(color: tokens.states.solvent, width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              if (task.stickerId != null) ...[
                StickerChip(stickerId: task.stickerId!),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(task.title, style: text.bodyLarge),
                    if (avoidedDays > 0)
                      Text('avoided $avoidedDays days',
                          style: text.labelMedium),
                  ],
                ),
              ),
              if (task.estimateMinutes != null) ...[
                const SizedBox(width: 8),
                Text('${task.estimateMinutes}m', style: text.labelMedium),
              ],
              const SizedBox(width: 10),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? tokens.states.solvent
                      : const Color(0x00000000),
                  border: Border.all(
                    color: selected ? tokens.states.solvent : tokens.inkFaint,
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

class _Empty extends StatelessWidget {
  const _Empty({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Text(
        // Two different states with two different answers: nothing matched, or
        // there is nothing to match.
        searching
            ? 'Nothing matches that.'
            : 'Your list is empty. Anything you make in Tasks and do not plan '
                'waits here.',
        style: text.bodyMedium,
        textAlign: TextAlign.center,
      ),
    );
  }
}
