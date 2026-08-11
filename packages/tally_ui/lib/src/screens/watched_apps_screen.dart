import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme_data.dart';

/// One app in the picker.
final class WatchableApp {
  const WatchableApp({
    required this.packageName,
    required this.label,
    required this.recentSeconds,
    this.watching = false,
    this.notInstalled = false,
  });

  final String packageName;
  final String label;

  /// Foreground time over the last week, from the OS.
  final int recentSeconds;

  final bool watching;
  final bool notInstalled;

  int get recentMinutes => (recentSeconds / 60).round();

  String get recentLabel {
    if (notInstalled) return 'not installed';
    if (recentSeconds <= 0) return 'no usage this week';
    final minutes = recentMinutes;
    if (minutes < 60) return '${minutes}m this week';
    return '${minutes ~/ 60}h ${minutes % 60}m this week';
  }
}

/// Watched apps, and every number that changes the ledger.
///
/// **One screen for the maths.** The plan puts the ratio, the allowance, the
/// caps and the day boundary here rather than scattered through Settings, so
/// there is never a second place to look for why a number came out the way it
/// did.
///
/// Apps are listed with **their own last-week usage**, so the choice is
/// informed rather than guessed. Suggested defaults are offered but never
/// pre-ticked: an app that starts counting your time without you saying so is
/// the behaviour this whole product exists to be the opposite of.
class WatchedAppsScreen extends StatelessWidget {
  const WatchedAppsScreen({
    required this.apps,
    required this.settings,
    required this.access,
    this.onToggle,
    this.onSettings,
    this.onGrantAccess,
    this.onClose,
    this.maxWatched = 10,
    super.key,
  });

  final List<WatchableApp> apps;
  final LedgerSettings settings;
  final UsageAccess access;

  final void Function(WatchableApp app, bool watching)? onToggle;
  final void Function(LedgerSettings settings)? onSettings;
  final VoidCallback? onGrantAccess;
  final VoidCallback? onClose;

  final int maxWatched;

  int get _watchedCount => apps.where((a) => a.watching).length;

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
                  if (onClose != null)
                    Semantics(
                      button: true,
                      label: 'Back',
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onClose,
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.arrow_back,
                            color: tokens.inkMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  Text('Watched apps', style: text.headlineMedium),
                  const Spacer(),
                  Text('$_watchedCount of $maxWatched', style: text.labelMedium),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (access != UsageAccess.granted)
                    _AccessCard(access: access, onGrant: onGrantAccess)
                  else ...[
                    Text(
                      'Time in these apps is what the balance pays for. '
                      'Change them any day.',
                      style: text.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    for (final app in apps)
                      _AppRow(
                        app: app,
                        atLimit: _watchedCount >= maxWatched && !app.watching,
                        onToggle: (value) => onToggle?.call(app, value),
                      ),
                    if (apps.isEmpty) _NoApps(),
                  ],
                  const SizedBox(height: 28),
                  Text('THE NUMBERS', style: text.labelSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Everything that decides what a minute is worth lives '
                    'here, so there is one place to look.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  _RuleChoice(
                    title: 'Earn rate',
                    detail: _ratioDetail(settings.earnRatio),
                    options: const {
                      '2 : 1': 0.5,
                      '1 : 1': 1.0,
                      '1 : 2': 2.0,
                    },
                    selected: settings.earnRatio,
                    onPick: (value) => onSettings?.call(
                      settings.copyWith(earnRatio: value as double),
                    ),
                  ),
                  _RuleChoice(
                    title: 'Free minutes a day',
                    detail: settings.dailyAllowanceMinutes == 0
                        ? 'None. Everything has to be earned.'
                        : 'Granted at the day boundary. Clears any debt '
                            'first, and never rolls over.',
                    options: const {
                      'none': 0,
                      '15': 15,
                      '30': 30,
                      '60': 60,
                    },
                    selected: settings.dailyAllowanceMinutes,
                    onPick: (value) => onSettings?.call(
                      settings.copyWith(dailyAllowanceMinutes: value as int),
                    ),
                  ),
                  _RuleChoice(
                    title: 'Most you can earn in a day',
                    detail: 'So one long study day does not buy a whole '
                        'weekend of scrolling.',
                    options: const {
                      '60': 60,
                      '90': 90,
                      '120': 120,
                      'no cap': -1,
                    },
                    selected: settings.dailyEarnCapMinutes ?? -1,
                    onPick: (value) => onSettings?.call(
                      value == -1
                          ? settings.copyWith(clearEarnCap: true)
                          : settings.copyWith(
                              dailyEarnCapMinutes: value as int,
                            ),
                    ),
                  ),
                  _RuleChoice(
                    title: 'Minutes that survive the night',
                    detail: 'Anything above this goes to savings, which can '
                        'never be spent on scrolling.',
                    options: const {'0': 0, '30': 30, '60': 60, '120': 120},
                    selected: settings.rolloverCapMinutes,
                    onPick: (value) => onSettings?.call(
                      settings.copyWith(rolloverCapMinutes: value as int),
                    ),
                  ),
                  _RuleChoice(
                    title: 'When a day starts',
                    detail: 'A session at 2am belongs to the night before. '
                        'This is where that line sits.',
                    options: const {
                      'midnight': 0,
                      '3am': 3,
                      '4am': 4,
                      '5am': 5,
                    },
                    selected: settings.dayBoundaryHour,
                    onPick: (value) => onSettings?.call(
                      settings.copyWith(dayBoundaryHour: value as int),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    // Stated once, plainly, because it is the rule that makes
                    // the whole ledger mean anything.
                    'Debt stops at −${settings.debtFloorMinutes} minutes, and '
                    'nothing is ever blocked.',
                    style: text.labelMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _ratioDetail(double ratio) {
    if (ratio == 1.0) return 'A minute focused buys a minute of scrolling.';
    if (ratio < 1.0) {
      final need = (1 / ratio).round();
      return '$need minutes focused buy one minute of scrolling.';
    }
    return 'One minute focused buys ${ratio.round()} minutes of scrolling.';
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.atLimit,
    required this.onToggle,
  });

  final WatchableApp app;
  final bool atLimit;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Opacity(
      opacity: atLimit ? 0.4 : 1,
      child: Semantics(
        toggled: app.watching,
        label: app.label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: atLimit ? null : () => onToggle(!app.watching),
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        app.label,
                        style: text.bodyLarge?.copyWith(
                          color: app.notInstalled
                              ? tokens.inkFaint
                              : tokens.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // The app's own last week, so the worst offenders sort
                      // to the top and the choice is informed.
                      Text(app.recentLabel, style: text.labelMedium),
                    ],
                  ),
                ),
                Switch(
                  value: app.watching,
                  onChanged: atLimit ? null : onToggle,
                  activeThumbColor: tokens.bg,
                  activeTrackColor: tokens.states.solvent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One rule, as a row of choices.
///
/// Choices rather than a free number field: every option here is one the ledger
/// is known to behave sensibly under, and a text box invites a value that makes
/// the app quietly nonsensical.
class _RuleChoice extends StatelessWidget {
  const _RuleChoice({
    required this.title,
    required this.detail,
    required this.options,
    required this.selected,
    required this.onPick,
  });

  final String title;
  final String detail;
  final Map<String, Object> options;
  final Object selected;
  final void Function(Object value) onPick;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.bodyLarge),
          const SizedBox(height: 2),
          Text(detail, style: text.bodyMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in options.entries)
                Semantics(
                  button: true,
                  selected: entry.value == selected,
                  label: '$title ${entry.key}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onPick(entry.value),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 40,
                      constraints: const BoxConstraints(minWidth: 56),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: entry.value == selected
                            ? tokens.states.solvent
                            : tokens.surface,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        entry.key,
                        style: text.bodyLarge?.copyWith(
                          color: entry.value == selected
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
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.access, required this.onGrant});

  final UsageAccess access;
  final VoidCallback? onGrant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    final (title, body) = switch (access) {
      UsageAccess.unavailable => (
          'This device cannot report app usage',
          'Tally works as a planner and a focus timer, but the spending half '
              'of it needs an API this device does not have.',
        ),
      _ => (
          'Tally needs usage access to see what you spend',
          'Android grants this in Settings rather than in the app. Nothing is '
              'sent anywhere: the numbers are read on the phone and stay on '
              'it. Without it, the plan and the timer still work.',
        ),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: text.bodyLarge),
          const SizedBox(height: 6),
          Text(body, style: text.bodyMedium),
          if (access != UsageAccess.unavailable) ...[
            const SizedBox(height: 14),
            Semantics(
              button: true,
              label: 'Open Settings',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onGrant,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tokens.states.solvent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Open Settings',
                    style: text.bodyLarge?.copyWith(
                      color: tokens.bg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoApps extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Text(
          'No apps to show yet. Use the phone for a while and the list will '
          'fill in.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
}
