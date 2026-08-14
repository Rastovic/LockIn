import 'package:flutter/material.dart';

import '../theme/tally_theme_data.dart';

/// Asking for one name.
///
/// Used where an object has nothing else worth asking about. A project holds
/// no time, no dates and no progress, so a full sheet for one would be four
/// fifths empty fields.
class NameSheet extends StatefulWidget {
  const NameSheet({
    required this.title,
    required this.controller,
    required this.onSave,
    this.hint = '',
    this.saveLabel = 'Save',
    super.key,
  });

  final String title;
  final String hint;
  final TextEditingController controller;
  final String saveLabel;
  final ValueChanged<String> onSave;

  @override
  State<NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<NameSheet> {
  late bool _canSave = widget.controller.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final can = widget.controller.text.trim().isNotEmpty;
    if (can != _canSave) setState(() => _canSave = can);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: text.titleLarge),
          const SizedBox(height: 14),
          TextField(
            controller: widget.controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            style: text.bodyLarge,
            cursorColor: tokens.states.solvent,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: text.bodyMedium,
              filled: true,
              fillColor: tokens.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 16),
          _SheetButton(
            label: widget.saveLabel,
            enabled: _canSave,
            onTap: () => widget.onSave(widget.controller.text.trim()),
          ),
        ],
      ),
    );
  }
}

/// A destructive action, stated plainly before it happens.
class ConfirmSheet extends StatelessWidget {
  const ConfirmSheet({
    required this.title,
    required this.detail,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final String title;
  final String detail;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.titleLarge),
          const SizedBox(height: 8),
          Text(detail, style: text.bodyMedium),
          const SizedBox(height: 18),
          _SheetButton(
            label: confirmLabel,
            enabled: true,
            danger: true,
            onTap: onConfirm,
          ),
          const SizedBox(height: 8),
          _SheetButton(label: 'Cancel', enabled: true, onTap: onCancel),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.enabled,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final fill = danger ? tokens.states.borrowing : tokens.states.solvent;

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
            color: enabled ? fill : tokens.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: text.bodyLarge?.copyWith(
              color: enabled ? tokens.bg : tokens.inkFaint,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
