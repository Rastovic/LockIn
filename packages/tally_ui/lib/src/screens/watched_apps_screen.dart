import 'package:flutter/material.dart';

import '../format/durations.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme.dart';
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

  int get recentMinutes => wholeMinutes(recentSeconds);

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
/// What happens when a watched app is opened with no minutes left.
enum BlockMode {
  /// Nothing. The app only counts.
  off,

  /// A page says the minutes are gone, with "Continue anyway". Time spent
  /// after that goes on the balance as debt, the same as with blocking off.
  remind,

  /// The same page with no way past it but earning more.
  block,
}

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
    this.theme,
    this.themeMode,
    this.onTheme,
    this.onOpenGoals,
    this.onOpenTour,
    this.onPrivacyPolicy,
    this.onPrivacyChoices,
    this.onCheckNumbers,
    this.onExportCsv,
    this.onOpenBackup,
    this.blocking,
    this.blockerOn = false,
    this.onBlocking,
    this.onOpenBlockerSettings,
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

  final TallyTheme? theme;
  final ThemeMode? themeMode;
  final void Function(TallyTheme, ThemeMode)? onTheme;
  final VoidCallback? onOpenGoals;

  /// Everything the app can do, listed. See [TourScreen].
  final VoidCallback? onOpenTour;

  /// Opens the privacy policy. Both stores require it to be reachable from
  /// inside the app, not only from the listing.
  final VoidCallback? onPrivacyPolicy;

  /// Re-opens the ad consent form. Null outside the regions where consent was
  /// asked for, since the form cannot be shown there.
  final VoidCallback? onPrivacyChoices;

  /// Opens the comparison against the phone's own counter.
  final VoidCallback? onCheckNumbers;
  final Future<void> Function()? onExportCsv;
  final VoidCallback? onOpenBackup;

  /// What happens at zero minutes. Null hides the section, for a platform
  /// with no blocker.
  final BlockMode? blocking;

  /// The system accessibility switch. Remind and block both need it.
  final bool blockerOn;
  final ValueChanged<BlockMode>? onBlocking;
  final VoidCallback? onOpenBlockerSettings;

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
                  else
                    _Fold(
                      title: 'WATCHED APPS',
                      summary: _watchedCount == 0
                          ? 'nothing watched yet'
                          : '$_watchedCount of ${apps.length}',
                      children: [
                        Text(
                          'Time in these apps is what the balance pays for. '
                          'Change them any day.',
                          style: text.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        for (final app in apps)
                          _AppRow(
                            app: app,
                            atLimit:
                                _watchedCount >= maxWatched && !app.watching,
                            onToggle: (value) => onToggle?.call(app, value),
                          ),
                        if (apps.isEmpty) _NoApps(),
                      ],
                    ),
                  if (blocking != null && access == UsageAccess.granted)
                    _Fold(
                      title: 'BLOCKING',
                      summary: switch ((blocking!, blockerOn)) {
                        (BlockMode.off, _) => 'off',
                        (_, false) => 'needs a switch in Settings',
                        (BlockMode.remind, true) => 'remind at zero',
                        (BlockMode.block, true) => 'block at zero',
                      },
                      children: [
                        _RuleChoice(
                          title: 'At zero minutes',
                          detail: switch (blocking!) {
                            BlockMode.off =>
                              'Watched apps open as usual. The balance just '
                                  'goes into debt.',
                            BlockMode.remind =>
                              'A page says your minutes are gone. You can '
                                  'continue anyway, and that time goes on '
                                  'your balance as debt.',
                            BlockMode.block =>
                              'A watched app is covered until you focus to '
                                  'earn more. No way past it.',
                          },
                          options: const {
                            'Off': BlockMode.off,
                            'Remind': BlockMode.remind,
                            'Block': BlockMode.block,
                          },
                          selected: blocking!,
                          onPick: (value) =>
                              onBlocking?.call(value as BlockMode),
                        ),
                        if (blocking != BlockMode.off && !blockerOn)
                          _BlockerCard(onOpen: onOpenBlockerSettings),
                      ],
                    ),
                  _Fold(
                    title: 'THE NUMBERS',
                    summary: 'what a minute is worth',
                    children: [
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
                    switch (blocking) {
                      BlockMode.block => 'Debt stops at '
                          '−${settings.debtFloorMinutes} minutes. Watched '
                          'apps are covered at zero.',
                      BlockMode.remind => 'Debt stops at '
                          '−${settings.debtFloorMinutes} minutes. Watched '
                          'apps remind you at zero.',
                      _ => 'Debt stops at −${settings.debtFloorMinutes} '
                          'minutes, and nothing is ever blocked.',
                    },
                    style: text.labelMedium,
                  ),
                    ],
                  ),
                  if (theme != null && onTheme != null)
                    _Fold(
                      title: 'LOOK',
                      summary: '${theme!.label}, '
                          '${switch (themeMode ?? ThemeMode.dark) {
                        ThemeMode.dark => 'dark',
                        ThemeMode.light => 'light',
                        ThemeMode.system => 'system',
                      }}',
                      children: [
                    _RuleChoice(
                      title: 'Theme',
                      detail: 'Two, and each is written in light and dark.',
                      options: {
                        for (final t in TallyTheme.values) t.label: t,
                      },
                      selected: theme!,
                      onPick: (value) => onTheme!(
                        value as TallyTheme,
                        themeMode ?? ThemeMode.dark,
                      ),
                    ),
                    _RuleChoice(
                      title: 'Light or dark',
                      detail: 'Following the system means LockIn changes when '
                          'your phone does.',
                      options: const {
                        'Dark': ThemeMode.dark,
                        'Light': ThemeMode.light,
                        'System': ThemeMode.system,
                      },
                      selected: themeMode ?? ThemeMode.dark,
                      onPick: (value) => onTheme!(
                        theme!,
                        value as ThemeMode,
                      ),
                    ),
                      ],
                    ),
                  _Fold(
                    title: 'ELSEWHERE',
                    summary: 'goals, backup, export, privacy',
                    children: [
                  if (onOpenTour != null)
                    _LinkRow(
                      label: 'What LockIn can do',
                      detail: 'Every feature on one page, and where to find '
                          'it.',
                      onTap: onOpenTour!,
                    ),
                  if (onCheckNumbers != null)
                    _LinkRow(
                      label: 'Check the numbers',
                      // Named for what it answers rather than what it does.
                      // "Diagnostics" would be read as something for me.
                      detail: 'Compare what LockIn counted against what your '
                          'phone says.',
                      onTap: onCheckNumbers!,
                    ),
                  if (onOpenGoals != null)
                    _LinkRow(
                      label: 'Goals',
                      detail: 'Year and someday. They never join a day.',
                      onTap: onOpenGoals!,
                    ),
                  if (onOpenBackup != null)
                    _LinkRow(
                      label: 'Backup and restore',
                      // Named as the thing that moves you to a new phone,
                      // because that is when someone comes looking for it.
                      detail: 'One file that carries everything to a new '
                          'phone.',
                      onTap: onOpenBackup!,
                    ),
                  if (onExportCsv != null)
                    _LinkRow(
                      label: 'Export the numbers',
                      // Says plainly what it is and is not, because the other
                      // export - the backup archive - is the one that
                      // round-trips, and confusing the two loses data.
                      detail: 'A spreadsheet to read. Not a backup: it cannot '
                          'be loaded back in.',
                      onTap: onExportCsv!,
                    ),
                  if (onPrivacyChoices != null)
                    _LinkRow(
                      label: 'Privacy choices',
                      detail: 'Change what you agreed to about ads.',
                      onTap: onPrivacyChoices!,
                    ),
                  if (onPrivacyPolicy != null)
                    _LinkRow(
                      label: 'Privacy policy',
                      // The honest summary first, the full text one tap away.
                      detail: 'Your data stays on this phone. No account, '
                          'no cloud, no ads.',
                      onTap: onPrivacyPolicy!,
                    ),
                    ],
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

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                    Text(label, style: text.bodyLarge),
                    Text(detail, style: text.labelMedium),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: tokens.inkFaint),
            ],
          ),
        ),
      ),
    );
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

/// The second switch blocking needs, which only the user can flip.
class _BlockerCard extends StatelessWidget {
  const _BlockerCard({required this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('One more switch, in Settings', style: text.bodyLarge),
          const SizedBox(height: 6),
          Text(
            'Find LockIn under Accessibility and turn it on. Nothing is '
            'covered until you do.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 14),
          Semantics(
            button: true,
            label: 'Open Accessibility settings',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onOpen,
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
          'LockIn works as a planner and a focus timer, but the spending half '
              'of it needs an API this device does not have.',
        ),
      _ => (
          'LockIn needs usage access to see what you spend',
          'Android grants this in Settings rather than in the app. Nothing is '
              'sent anywhere: the numbers are read on the phone and stay on '
              'it. Without it, the plan and the timer still work.',
        ),
    };

    return Padding(
      // Same gap _Fold leaves under itself, so the card does not sit flush
      // against the section header below it.
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
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

/// A settings section that starts closed.
///
/// Settings was one flat scroll: every watched app, then every rule, then the
/// theme, then backup and export. On a phone with a normal number of apps
/// installed, reaching Backup meant scrolling past the whole app list, and the
/// things people look for least often sat furthest away.
///
/// Folded, the screen opens as four headers you can read at once. Each carries
/// a one-line summary of its current state so the common question - what is
/// this set to - is answered without opening anything.
class _Fold extends StatefulWidget {
  const _Fold({
    required this.title,
    required this.summary,
    required this.children,
  });

  final String title;
  final String summary;
  final List<Widget> children;

  @override
  State<_Fold> createState() => _FoldState();
}

class _FoldState extends State<_Fold> {
  /// **Every section starts closed**, including the app list.
  ///
  /// One of them used to open itself when nothing was being watched, on the
  /// theory that a new user needs to see it. It made the screen open at a
  /// different height depending on state, and the point of folding was to make
  /// Settings a short index you can read at once. An index with one section
  /// already unrolled is not an index.
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: _open,
            label: '${widget.title}, ${widget.summary}',
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => setState(() => _open = !_open),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title, style: text.labelSmall),
                          const SizedBox(height: 2),
                          Text(
                            widget.summary,
                            style: text.bodyMedium
                                ?.copyWith(color: tokens.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _open ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: tokens.inkFaint,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.children,
              ),
            ),
        ],
      ),
    );
  }
}
