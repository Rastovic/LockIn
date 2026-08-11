import 'package:flutter/material.dart';
import 'package:vitals_archive/vitals_archive.dart';

import '../theme/tally_theme_data.dart';

/// Backup and restore.
///
/// Two buttons and a lot of plain speaking. This is the screen where a
/// misunderstanding costs someone a year of history, so nothing about what each
/// one does is left to be inferred.
class BackupSheet extends StatelessWidget {
  const BackupSheet({
    required this.onExport,
    required this.onRestore,
    this.busy = false,
    super.key,
  });

  final Future<void> Function() onExport;
  final Future<void> Function() onRestore;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
          Text('Backup', style: text.titleLarge),
          const SizedBox(height: 6),
          Text(
            // The honest framing. Android's own backup is real but silent,
            // capped, and does nothing across accounts - so it is described as
            // what it is rather than relied on.
            'One file with everything in it. Keep it somewhere you can find '
            'again, and a new phone picks up exactly where this one left off.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 18),
          _Action(
            label: 'Create a backup file',
            detail: 'Tasks, sessions, days, stickers, goals and settings.',
            primary: true,
            enabled: !busy,
            onTap: onExport,
          ),
          const SizedBox(height: 8),
          _Action(
            label: 'Restore from a file',
            detail: 'You will see what is in it before anything changes.',
            primary: false,
            enabled: !busy,
            onTap: onRestore,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              // Said once, plainly. The file is not encrypted, and a user who
              // assumes it is might put it somewhere they should not.
              'The file holds your full history in readable form and is not '
              'password protected. Keep it somewhere private.',
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// What a restore is about to do, shown before it does it.
///
/// **A restore must never be a surprise.** Overwriting a year of history by
/// accident is unforgivable and entirely preventable, so the confirmation
/// states the counts, the date range and the fact that it replaces everything.
class RestoreConfirmSheet extends StatelessWidget {
  const RestoreConfirmSheet({
    required this.preview,
    required this.onConfirm,
    required this.onCancel,
    super.key,
  });

  final ImportPreview preview;
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
          Text('Restore this backup?', style: text.titleLarge),
          const SizedBox(height: 10),
          Text(preview.summary, style: text.bodyMedium),
          const SizedBox(height: 12),
          Text(
            'Made by ${preview.manifest.app} '
            '${preview.manifest.appVersion} on '
            '${preview.manifest.device['model'] ?? 'another device'}.',
            style: text.labelMedium,
          ),
          if (preview.hadLosses) ...[
            const SizedBox(height: 12),
            Text(
              // Never silent. A partially readable file still restores, but the
              // user is told rather than left to discover a gap later.
              '${preview.skipped.length} rows in the file could not be read '
              'and will be skipped.',
              style: text.bodyMedium?.copyWith(color: tokens.states.low),
            ),
          ],
          const SizedBox(height: 20),
          _Action(
            label: 'Replace everything',
            detail: 'This cannot be undone.',
            primary: true,
            enabled: true,
            danger: true,
            onTap: () async => onConfirm(),
          ),
          const SizedBox(height: 8),
          _Action(
            label: 'Cancel',
            detail: 'Nothing has changed yet.',
            primary: false,
            enabled: true,
            onTap: () async => onCancel(),
          ),
        ],
      ),
    );
  }
}

/// The outcome, including what verification found.
class RestoreResultSheet extends StatelessWidget {
  const RestoreResultSheet({
    required this.verification,
    required this.onClose,
    this.error,
    super.key,
  });

  final ImportVerification? verification;

  /// Set when the file was refused. Nothing was written.
  final ArchiveError? error;

  final VoidCallback onClose;

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
          Text(
            error == null ? 'Restored' : 'Not restored',
            style: text.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error?.message ??
                verification?.message ??
                'Everything is back.',
            style: text.bodyMedium,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(
              // The reassurance that matters most after a failed restore.
              'Nothing on this phone was changed.',
              style: text.bodyMedium,
            ),
          ],
          const SizedBox(height: 20),
          _Action(
            label: 'Done',
            detail: '',
            primary: true,
            enabled: true,
            onTap: () async => onClose(),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.detail,
    required this.primary,
    required this.enabled,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final String detail;
  final bool primary;
  final bool enabled;
  final Future<void> Function() onTap;
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
        onTap: enabled ? () => onTap() : null,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: primary ? fill : tokens.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: text.bodyLarge?.copyWith(
                  color: primary ? tokens.bg : tokens.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detail.isNotEmpty)
                Text(
                  detail,
                  style: text.labelMedium?.copyWith(
                    color: primary
                        ? tokens.bg.withValues(alpha: 0.75)
                        : tokens.inkFaint,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
