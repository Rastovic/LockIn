import 'package:flutter/material.dart';

import '../format/durations.dart';
import 'package:tally_engine/tally_engine.dart';

import '../theme/tally_theme_data.dart';
import '../widgets/balance_strip.dart';

/// The steps: three swipeable cards for the loop, then the setup.
///
/// **The cards show the loop and nothing else.** Everything past it - widgets,
/// blocking, stats, goals - is taught where it lives, the first time that
/// screen opens, and all of it is listed under Settings. A first run that
/// explains every feature is one people swipe through without reading.
///
/// **Ordered access-before-picking, which differs from the plan's list.** The
/// plan says "pick watched apps, grant usage access". The picker's whole value
/// is showing each app's own last-week usage so the choice is informed, and
/// that data does not exist until access is granted - so asking first would
/// mean presenting a bare list of names and then asking again. Access comes
/// first, and the reason for it is the step before that.
enum OnboardingStep {
  /// The loop, first card: a day is one list.
  plan,

  /// Second card: doing things earns minutes.
  earn,

  /// Third card: the watched apps spend them.
  what,

  /// Why usage access is needed, then the ask.
  usageAccess,

  /// Which apps count.
  pickApps,

  /// Why notifications are useful, then the ask.
  notifications,
}

/// First run.
///
/// This is the funnel the whole product depends on, and the step that kills
/// trackers is usage access. Two rules follow from that and shape every screen
/// here:
///
/// - **The reason is on screen before the ask, every time.** Both stores expect
///   it, and a permission dialog that arrives cold is the single biggest cause
///   of a refusal that never gets reversed.
/// - **Every step can be skipped, and the app says what skipping costs.** A
///   funnel that traps someone produces a grant they resent and an uninstall
///   the same week.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    required this.step,
    required this.access,
    this.apps = const [],
    this.notificationsGranted = false,
    this.onNext,
    this.onSkip,
    this.onBack,
    this.onGrantUsage,
    this.onGrantNotifications,
    this.onToggleApp,
    super.key,
  });

  final OnboardingStep step;
  final UsageAccess access;
  final List<WatchableAppSummary> apps;
  final bool notificationsGranted;

  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  /// A swipe back on the cards. The setup steps do not swipe: a stray swipe
  /// past a permission ask would skip the reason for it.
  final VoidCallback? onBack;
  final VoidCallback? onGrantUsage;
  final VoidCallback? onGrantNotifications;
  final void Function(String packageName, bool watching)? onToggleApp;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Progress(step: step),
            Expanded(
              child: _Swipe(
                enabled: step.isIntro,
                onNext: onNext,
                onBack: onBack,
                child: switch (step) {
                  OnboardingStep.plan => const _PlanCard(),
                  OnboardingStep.earn => const _EarnCard(),
                  OnboardingStep.what => _WhatItDoes(),
                  OnboardingStep.usageAccess => _UsageAccess(
                    access: access,
                    onGrant: onGrantUsage,
                  ),
                  OnboardingStep.pickApps => _PickApps(
                    apps: apps,
                    onToggle: onToggleApp,
                  ),
                  OnboardingStep.notifications => _Notifications(
                    granted: notificationsGranted,
                    onGrant: onGrantNotifications,
                  ),
                },
              ),
            ),
            _Actions(
              step: step,
              access: access,
              pickedCount: apps.where((a) => a.watching).length,
              notificationsGranted: notificationsGranted,
              onNext: onNext,
              onSkip: onSkip,
            ),
          ],
        ),
      ),
    );
  }
}

extension OnboardingStepIntro on OnboardingStep {
  /// The cards that explain, as opposed to the steps that ask.
  bool get isIntro =>
      this == OnboardingStep.plan ||
      this == OnboardingStep.earn ||
      this == OnboardingStep.what;
}

/// Turns a horizontal fling into next or back.
///
/// A fling rather than a drag distance, so scrolling a card vertically never
/// turns the page by accident.
class _Swipe extends StatelessWidget {
  const _Swipe({
    required this.enabled,
    required this.child,
    this.onNext,
    this.onBack,
  });

  final bool enabled;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (v < -250) onNext?.call();
        if (v > 250) onBack?.call();
      },
      child: child,
    );
  }
}

/// A row as the Today list draws it, for the cards. Not a real [TaskRow]:
/// that needs a plan entry and a task behind it, and these are pictures.
class _SampleRow extends StatelessWidget {
  const _SampleRow({
    required this.title,
    required this.trailing,
    this.done = false,
    this.note,
  });

  final String title;
  final String trailing;
  final bool done;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            done ? '●' : '○',
            style: text.bodyLarge?.copyWith(color: tokens.states.solvent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.bodyLarge?.copyWith(
                    color: done ? tokens.inkFaint : tokens.ink,
                  ),
                ),
                if (note != null) Text(note!, style: text.labelMedium),
              ],
            ),
          ),
          Text(
            trailing,
            style: text.bodyMedium?.copyWith(
              color: done ? tokens.states.solvent : tokens.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        Text('A day is\none list.', style: text.headlineMedium),
        const SizedBox(height: 14),
        Text(
          'Write tasks down once and put them on a day when you mean to do '
          'them. Habits and repeating tasks add themselves on the days they '
          'are due.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 28),
        const _SampleRow(title: 'Piano', trailing: '20 min', note: 'habit'),
        const _SampleRow(title: 'Reply to the landlord', trailing: '10 min'),
        const _SampleRow(title: 'Tax return', trailing: '45 min'),
      ],
    );
  }
}

class _EarnCard extends StatelessWidget {
  const _EarnCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        Text('Doing it\nearns minutes.', style: text.headlineMedium),
        const SizedBox(height: 14),
        Text(
          'Tick a task and it pays its estimate. Or press play and focus on '
          'it: the clock runs with the screen off, and an alarm says when the '
          'block is over.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 28),
        const _SampleRow(title: 'Piano', trailing: '+20', done: true),
        const _SampleRow(
          title: 'Reply to the landlord',
          trailing: '+10',
          done: true,
        ),
        const _SampleRow(title: 'Tax return', trailing: '45 min'),
      ],
    );
  }
}

/// An app in the onboarding picker.
final class WatchableAppSummary {
  const WatchableAppSummary({
    required this.packageName,
    required this.label,
    required this.recentSeconds,
    this.watching = false,
  });

  final String packageName;
  final String label;
  final int recentSeconds;
  final bool watching;

  String get weekly {
    final minutes = wholeMinutes(recentSeconds);
    if (minutes <= 0) return 'no usage this week';
    if (minutes < 60) return '${minutes}m last week';
    return '${minutes ~/ 60}h ${minutes % 60}m last week';
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.step});

  final OnboardingStep step;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          for (final s in OnboardingStep.values) ...[
            Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: s.index <= step.index
                      ? tokens.states.solvent
                      : tokens.surfaceStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            if (s != OnboardingStep.values.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _WhatItDoes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        Text(
          'Scrolling costs\nminutes you earned.',
          style: text.headlineMedium,
        ),
        const SizedBox(height: 14),
        Text(
          'Time in the apps you pick spends the minutes you earned. Go past '
          'zero and you are borrowing.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 28),
        // The idea shown rather than described: the strip in three states is
        // the whole product in one glance.
        for (final (seconds, note) in [
          (2520, 'earned and unspent'),
          (420, 'running low'),
          (-1080, 'borrowing, and it says so'),
        ]) ...[
          BalanceStrip(spendableSeconds: seconds, solvencyStreak: 6),
          Padding(
            padding: const EdgeInsets.only(left: 18, bottom: 14),
            child: Text(note, style: text.labelMedium),
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            // The differentiator, stated first rather than buried. Every app in
            // this category blocks, and that is why they get uninstalled.
            // Blocking now exists, but only if the user turns it on.
            'LockIn never blocks anything unless you ask it to. It keeps an '
            'honest count and lets the number do the work.',
            style: text.bodyLarge,
          ),
        ),
      ],
    );
  }
}

class _UsageAccess extends StatelessWidget {
  const _UsageAccess({required this.access, required this.onGrant});

  final UsageAccess access;
  final VoidCallback? onGrant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;
    final granted = access == UsageAccess.granted;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        Text(
          granted
              ? 'Usage access is on.'
              : 'LockIn needs to see\nwhat you use.',
          style: text.headlineMedium,
        ),
        const SizedBox(height: 14),
        Text(
          granted
              ? 'That is the only permission LockIn asks for that it cannot do '
                    'without.'
              : 'Android keeps app usage behind a permission you grant in '
                    'Settings rather than in the app. Without it LockIn cannot '
                    'tell when you are scrolling, so the balance would never '
                    'move.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 20),
        // The three things a reasonable person wants to know before granting a
        // permission that sounds invasive. Stated before the button, never
        // after.
        for (final (title, detail) in const [
          (
            'It stays on your phone',
            'Nothing is uploaded. There is no account and no server to send '
                'it to.',
          ),
          (
            'Only the apps you pick',
            'LockIn reads how long an app was open, for the apps you choose. '
                'It cannot see inside them.',
          ),
          (
            'You can turn it off',
            'Revoke it in Settings whenever you like. The plan and the timer '
                'keep working.',
          ),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: tokens.states.solvent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.bodyLarge),
                      Text(detail, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (!granted)
          _Primary(
            label: 'Open Settings',
            onTap: onGrant,
            // Named for what it does, not "Allow": the button opens a system
            // screen and the user has to find a switch there. Promising
            // otherwise makes it feel broken.
          ),
        if (access == UsageAccess.unavailable) ...[
          const SizedBox(height: 12),
          Text(
            'This device does not offer usage access at all. LockIn still works '
            'as a planner and a focus timer.',
            style: text.bodyMedium,
          ),
        ],
      ],
    );
  }
}

class _PickApps extends StatelessWidget {
  const _PickApps({required this.apps, required this.onToggle});

  final List<WatchableAppSummary> apps;
  final void Function(String packageName, bool watching)? onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        Text('Which apps\nshould cost you?', style: text.headlineMedium),
        const SizedBox(height: 14),
        Text(
          apps.isEmpty
              ? 'Nothing to show yet. You can pick apps any time from '
                    'Settings.'
              : 'Sorted by how long you spent in each last week. Pick the ones '
                    'you would rather spend less time in. You can change this '
                    'any day.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 18),
        for (final app in apps.take(14))
          Semantics(
            toggled: app.watching,
            label: app.label,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onToggle?.call(app.packageName, !app.watching),
              behavior: HitTestBehavior.opaque,
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: app.watching
                      ? Border.all(color: tokens.states.solvent, width: 1.5)
                      : null,
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
                            style: text.bodyLarge,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(app.weekly, style: text.labelMedium),
                        ],
                      ),
                    ),
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: app.watching
                            ? tokens.states.solvent
                            : const Color(0x00000000),
                        border: Border.all(
                          color: app.watching
                              ? tokens.states.solvent
                              : tokens.inkFaint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _Notifications extends StatelessWidget {
  const _Notifications({required this.granted, required this.onGrant});

  final bool granted;
  final VoidCallback? onGrant;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      children: [
        Text(
          granted
              ? 'That is everything.'
              : 'One notice, at\nthe moment it\nmatters.',
          style: text.headlineMedium,
        ),
        const SizedBox(height: 14),
        Text(
          granted
              ? 'LockIn is ready. Plan a day, focus on something, and watch what '
                    'it costs when you scroll.'
              : 'LockIn can tell you the moment your balance hits zero, so you '
                    'get five free minutes of warning before you start '
                    'borrowing.',
          style: text.bodyMedium,
        ),
        if (!granted) ...[
          const SizedBox(height: 18),
          Text(
            // The cap is stated up front. An app that promises restraint and
            // then sends six notifications gets all of them turned off.
            'Three a day at most, and all of them can be turned off. LockIn '
            'does not send streaks, tips, or anything trying to pull you back '
            'in.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 22),
          _Primary(label: 'Allow notifications', onTap: onGrant),
          const SizedBox(height: 12),
          Text(
            'Say no and everything still works. The warning shows up in the '
            'app instead, next time you open it.',
            style: text.bodyMedium,
          ),
        ],
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.step,
    required this.access,
    required this.pickedCount,
    required this.notificationsGranted,
    required this.onNext,
    required this.onSkip,
  });

  final OnboardingStep step;
  final UsageAccess access;
  final int pickedCount;
  final bool notificationsGranted;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    final (primary, skip) = switch (step) {
      OnboardingStep.plan || OnboardingStep.earn => ('Next', 'Skip to setup'),
      OnboardingStep.what => ('Next', null),
      OnboardingStep.usageAccess => (
        access == UsageAccess.granted ? 'Next' : 'Continue without it',
        null,
      ),
      OnboardingStep.pickApps => (
        pickedCount == 0 ? 'Skip for now' : 'Next',
        null,
      ),
      OnboardingStep.notifications => (
        notificationsGranted ? 'Start' : 'Start without notifications',
        null,
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          Semantics(
            button: true,
            label: primary,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onNext,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.states.solvent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  primary,
                  style: text.bodyLarge?.copyWith(
                    color: tokens.bg,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          if (skip != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onSkip,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: 44,
                child: Center(child: Text(skip, style: text.bodyMedium)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Primary extends StatelessWidget {
  const _Primary({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

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
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: tokens.states.solvent),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: tokens.states.solvent,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
