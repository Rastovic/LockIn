import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';
import 'package:vitals_core/vitals_core.dart';

/// The native spike, made checkable.
///
/// Phase 3's done-when is *"your own TikTok minutes from yesterday match
/// Digital Wellbeing"*, so this screen exists to be held next to Digital
/// Wellbeing and compared. It is not a shipping screen.
///
/// Read it in this order: access first, then the app list, then yesterday and
/// today per app. If the totals disagree with Wellbeing by more than a minute
/// or two, the spike has failed and the app is in trouble - that is the whole
/// point of checking before the rest is built on top.
class UsageSpikeScreen extends StatefulWidget {
  const UsageSpikeScreen({required this.source, super.key});

  final UsageSource source;

  @override
  State<UsageSpikeScreen> createState() => _UsageSpikeScreenState();
}

class _UsageSpikeScreenState extends State<UsageSpikeScreen> {
  UsageAccess _access = UsageAccess.denied;
  List<InstalledApp> _apps = const [];
  final Map<String, ({int yesterday, int today})> _totals = {};
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final access = await widget.source.access();
      var apps = <InstalledApp>[];
      if (access == UsageAccess.granted) {
        apps = await widget.source.installedApps();
        apps = apps.take(12).toList();
        await _loadTotals(apps);
      }
      if (!mounted) return;
      setState(() {
        _access = access;
        _apps = apps;
        _busy = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _busy = false;
      });
    }
  }

  /// Totals per app for yesterday and today so far.
  ///
  /// Day boundaries are the app's own 04:00 one, not midnight, because that is
  /// what every other number in Tally uses and a spike that agrees with
  /// Wellbeing but disagrees with the ledger has proved nothing.
  Future<void> _loadTotals(List<InstalledApp> apps) async {
    final engine = LedgerEngine(
      offsetAt: (i) => i.toLocal().timeZoneOffset.inMinutes,
    );
    final now = DateTime.now().toUtc();
    final todayKey = engine.dayKeyAt(now);
    final yesterdayKey = addDays(todayKey, -1);

    _totals.clear();
    for (final app in apps) {
      final yesterday = await widget.source.spans(
        from: engine.dayStart(yesterdayKey),
        to: engine.dayStart(todayKey),
        packages: [app.packageName],
      );
      final today = await widget.source.spans(
        from: engine.dayStart(todayKey),
        to: now,
        packages: [app.packageName],
      );
      _totals[app.packageName] = (
        yesterday: yesterday.fold(0, (a, s) => a + s.seconds),
        today: today.fold(0, (a, s) => a + s.seconds),
      );
    }
  }

  String _hm(int seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '${minutes}m';
    return '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text('Usage spike', style: text.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'Hold this next to Digital Wellbeing. If the numbers disagree '
                'by more than a minute or two, the spike has failed.',
                style: text.bodyMedium,
              ),
              const SizedBox(height: 20),
              _AccessCard(
                access: _access,
                onGrant: () async {
                  await widget.source.requestAccess();
                  // The user leaves for Settings and comes back; there is no
                  // callback, so the check runs again on return.
                  await Future<void>.delayed(const Duration(seconds: 1));
                  await _refresh();
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text('Error: $_error',
                    style: text.bodyMedium?.copyWith(
                      color: tokens.states.borrowing,
                    )),
              ],
              if (_busy) ...[
                const SizedBox(height: 24),
                Center(
                  child: CircularProgressIndicator(
                    color: tokens.states.solvent,
                  ),
                ),
              ],
              if (_access == UsageAccess.granted && !_busy) ...[
                const SizedBox(height: 20),
                Text('TOP APPS, LAST 7 DAYS', style: text.labelSmall),
                const SizedBox(height: 10),
                for (final app in _apps)
                  _AppRow(
                    app: app,
                    yesterday: _totals[app.packageName]?.yesterday ?? 0,
                    today: _totals[app.packageName]?.today ?? 0,
                    format: _hm,
                  ),
                if (_apps.isEmpty)
                  Text(
                    'No apps reported any usage. On a fresh emulator that is '
                    'expected: nothing has been used yet.',
                    style: text.bodyMedium,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.access, required this.onGrant});

  final UsageAccess access;
  final Future<void> Function() onGrant;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    final (label, detail, color) = switch (access) {
      UsageAccess.granted => (
          'Usage access granted',
          'The numbers below come from UsageStatsManager.',
          tokens.states.solvent,
        ),
      UsageAccess.denied => (
          'Usage access not granted',
          'LockIn cannot see any spending until this is on. Everything else '
              'in the app still works.',
          tokens.states.low,
        ),
      UsageAccess.unavailable => (
          'No usage API on this platform',
          'Expected in the web preview. On a phone this means the OEM removed '
              'it, which is a device LockIn cannot support.',
          tokens.states.borrowing,
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
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(label, style: text.bodyLarge)),
            ],
          ),
          const SizedBox(height: 6),
          Text(detail, style: text.bodyMedium),
          if (access == UsageAccess.denied) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onGrant,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tokens.states.solvent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Open Settings',
                  style: text.bodyLarge?.copyWith(color: tokens.bg),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AppRow extends StatelessWidget {
  const _AppRow({
    required this.app,
    required this.yesterday,
    required this.today,
    required this.format,
  });

  final InstalledApp app;
  final int yesterday;
  final int today;
  final String Function(int) format;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.label, style: text.bodyLarge),
                Text(app.packageName, style: text.labelMedium),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'yest ${format(yesterday)}',
                style: text.labelMedium?.copyWith(color: tokens.ink),
              ),
              Text('today ${format(today)}', style: text.labelMedium),
            ],
          ),
        ],
      ),
    );
  }
}
