import 'package:flutter/material.dart';
import 'package:tally_engine/tally_engine.dart';
import 'package:tally_ui/tally_ui.dart';

import 'demo_data.dart';

/// A harness for looking at the real screens before any of this ships.
///
/// It exists because a design decision cannot be judged from a description, and
/// running the app is the cheapest way to see one. **Play has nothing to do
/// with testing** - this runs on the web, on a desktop window, on an emulator
/// or on a phone over USB, and none of those involve a store.
///
/// The screens here are the shipping screens. Only the data source is
/// different: a fixed Tuesday instead of a database.
class PreviewApp extends StatefulWidget {
  const PreviewApp({super.key});

  @override
  State<PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<PreviewApp> {
  TallyTheme _theme = TallyTheme.aurora;
  Brightness _brightness = Brightness.dark;
  DemoState _state = DemoState.solvent;

  List<PlanEntry> _plan = DemoDay.plan();

  @override
  Widget build(BuildContext context) {
    final empty = _state == DemoState.empty;
    final view = DemoDay.planner.buildToday(
      dayKey: DemoDay.dayKey,
      tasks: DemoDay.tasks,
      plan: empty ? const [] : _plan,
      now: DemoDay.now,
    );

    return MaterialApp(
      title: 'Tally preview',
      debugShowCheckedModeBanner: false,
      theme: TallyThemeBuilder.build(_theme, _brightness),
      home: _PreviewShell(
        theme: _theme,
        brightness: _brightness,
        state: _state,
        onTheme: (t) => setState(() => _theme = t),
        onBrightness: (b) => setState(() => _brightness = b),
        onState: (s) => setState(() {
          _state = s;
          _plan = DemoDay.plan();
        }),
        child: TodayScreen(
          model: TodayScreenModel(
            view: view,
            spendableSeconds: _state.spendableSeconds,
            solvencyStreak: _state.streak,
            dateLabel: 'Tue 11 August',
            suggestion:
                empty ? null : DemoDay.suggestion(shippedLibrary),
            graceNotice: _state.notice,
          ),
          onToggle: (entry) => setState(() {
            if (entry.isDone) {
              _plan = DemoDay.planner
                  .uncomplete(
                    plan: _plan,
                    stamps: const [],
                    entryId: entry.id,
                  )
                  .plan;
            } else {
              _plan = DemoDay.planner
                  .complete(
                    plan: _plan,
                    entryId: entry.id,
                    tasks: DemoDay.tasks,
                    at: DemoDay.now,
                    dayKey: DemoDay.dayKey,
                  )
                  .plan;
            }
          }),
          onReorder: (from, to) => setState(() {
            _plan = DemoDay.planner.reorder(
              dayKey: DemoDay.dayKey,
              plan: _plan,
              fromIndex: from,
              toIndex: to,
            );
          }),
          onAcceptHabit: (habit) => setState(() {
            _plan = DemoDay.planner.addToDay(
              dayKey: DemoDay.dayKey,
              plan: _plan,
              taskIds: [habit.id],
              source: PlanSource.habit,
            );
          }),
          onStartFocus: (_) {},
          onOpenBalance: () {},
          onOpenPool: () {},
          onStartSession: () {},
        ),
      ),
    );
  }
}

/// Puts the screen in a phone-shaped frame with the switches beside it.
///
/// On a narrow window the frame fills it, so this is also how the app looks on
/// a real device.
class _PreviewShell extends StatelessWidget {
  const _PreviewShell({
    required this.theme,
    required this.brightness,
    required this.state,
    required this.onTheme,
    required this.onBrightness,
    required this.onState,
    required this.child,
  });

  final TallyTheme theme;
  final Brightness brightness;
  final DemoState state;
  final ValueChanged<TallyTheme> onTheme;
  final ValueChanged<Brightness> onBrightness;
  final ValueChanged<DemoState> onState;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 760;
    if (!wide) return child;

    return Container(
      color: const Color(0xFF14171C),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 250, child: _Controls(
              theme: theme,
              brightness: brightness,
              state: state,
              onTheme: onTheme,
              onBrightness: onBrightness,
              onState: onState,
            )),
            Expanded(
              child: Center(
                child: Container(
                  width: 390,
                  height: 800,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(34),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 40,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: MediaQuery(
                    // A phone's real inset, so the strip is not judged sitting
                    // flush against the top of a desktop window.
                    data: MediaQuery.of(context).copyWith(
                      padding: const EdgeInsets.only(top: 44, bottom: 20),
                    ),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.theme,
    required this.brightness,
    required this.state,
    required this.onTheme,
    required this.onBrightness,
    required this.onState,
  });

  final TallyTheme theme;
  final Brightness brightness;
  final DemoState state;
  final ValueChanged<TallyTheme> onTheme;
  final ValueChanged<Brightness> onBrightness;
  final ValueChanged<DemoState> onState;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(
        color: Color(0xFFE8ECF1),
        fontSize: 13,
        fontFamily: 'system-ui',
      ),
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Tally preview',
            style: TextStyle(
              color: Color(0xFFE8ECF1),
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'The shipping screens, driven by the real engines. '
            'Only the data source differs.',
            style: TextStyle(color: Color(0xFF8B95A3), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 22),
          const _Label('Theme'),
          for (final t in TallyTheme.values)
            _Choice(
              label: t.label,
              selected: theme == t,
              onTap: () => onTheme(t),
            ),
          const SizedBox(height: 18),
          const _Label('Mode'),
          for (final b in Brightness.values)
            _Choice(
              label: b == Brightness.dark ? 'Dark' : 'Light',
              selected: brightness == b,
              onTap: () => onBrightness(b),
            ),
          const SizedBox(height: 18),
          const _Label('State'),
          for (final s in DemoState.values)
            _Choice(
              label: s.label,
              selected: state == s,
              onTap: () => onState(s),
            ),
          const SizedBox(height: 22),
          const Text(
            'Rows tick, reorder on long press, and habits accept. '
            'All of it runs through the real planner.',
            style: TextStyle(color: Color(0xFF6C7787), fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF6C7787),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      );
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF232932) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? const Color(0xFFE8ECF1)
                  : const Color(0xFF8B95A3),
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
}
