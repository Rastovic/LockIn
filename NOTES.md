# Build notes

Decisions taken while building that differ from the plans in `~/Documents/apps`.
Anything here should eventually be folded back into the plan docs.

---

## Pub workspaces instead of `melos bootstrap`

`00-foundation/PHASE-0-SETUP.md` specifies melos. This repo uses **native Dart
pub workspaces** instead: the root `pubspec.yaml` lists every package under
`workspace:`, each package declares `resolution: workspace`, and one
`flutter pub get` at the root resolves them all against a single lockfile.

Why: pub workspaces are built into the SDK from Dart 3.6, and melos 7 is now a
thin task runner on top of them rather than a dependency manager. Using them
directly removes a global tool from the setup path with no loss.

Melos may still be added later purely as a task runner for `melos analyze` and
`melos test` across packages. It is not needed to build.

## Two contrast defects found in `DESIGN-SYSTEM.md`

Both found by `packages/vitals_ui/test/theme_test.dart`, which measures every
accent rather than trusting the spec. The spec has been corrected.

1. **White text on the coral and violet accents fails WCAG AA.** Section 1 said
   `onAccent` is `#FFFFFF` for those. Measured at 15px w600, which WCAG counts
   as normal text needing 4.5:1: interval red 3.27, magenta 3.25, coral 2.59.
   Ink `#0E1116` wins on twelve of the thirteen accents.
2. **`onAccent` cannot be a per-accent constant.** Stitchbook's berry is dark in
   light mode (needs white, 7.19) and light in dark mode (needs ink, 6.30), so
   the token is per-brightness. `AppAccent.onAccentFor(Brightness)` replaced the
   single `onAccent` field.

## `ThemeExtension` field-name collision

`VitalsThemeData` originally had a field named `type`. `ThemeExtension` declares
`Object get type` and uses it as the key the extension is stored under in
`ThemeData.extensions`, so the field silently overrode it: the extension was
filed under the typography instance, every `VitalsTheme.of(context)` threw, and
the code still analyzed clean. The field is now `typography`, with a regression
test asserting `theme.extensions.keys` contains `VitalsThemeData`.

## UUID v7 ordering is millisecond-granular

`DATA-PORTABILITY.md` rule 1 picks UUID keys, and v7 was chosen for index
locality. The ordering guarantee only holds **across** milliseconds: ids minted
inside the same millisecond carry random sub-millisecond bits and may sort
either way. Nothing may break a tie by id order. Rows needing a definite order
carry an explicit `sortOrder`; rows needing a time carry an explicit timestamp.

## Day keys are computed in UTC

`daysBetween` first used local `DateTime` arithmetic and returned 1 for
28 to 30 March, because that local span is 47 hours. A day key is a calendar
label rather than an instant, so `parseDayKey`, `addDays` and `daysBetween` all
work in UTC. The DST test in `day_key_test.dart` is the regression guard.

## Two ledger facts the tests pinned down

Both were found by writing the test before trusting the arithmetic.

**A 120-minute binge takes two days of allowance to clear, not one.** Spend
120: 30 allowance, 5 grace, then debt, floored at -60. The next day's 30-minute
allowance leaves -30, and only the day after closes at zero. So the solvency
streak stays broken for two days. That is the intended cost of a bad night, and
`ledger_engine_test.dart` asserts the whole three-day shape rather than just the
first day.

**Spendable minutes floor towards negative infinity, never towards zero.**
90 seconds of debt displays as -2 minutes, not -1. Rounding a debt towards zero
flatters the number, which is the one thing this app must never do.

## LedgerEngine lives in a pure Dart package

`packages/tally_engine` has no Flutter and no plugin dependency at all. Tally's
plan says "the engine imports nothing platform-specific, ever"; putting it in a
package that *cannot* import Flutter makes that structural instead of
remembered. Android supplies spend as `UsageSpan`s from `UsageStatsManager`;
iOS, which has no equivalent API, supplies coarser spans built from
`DeviceActivityMonitor` threshold callbacks. Neither is visible from the engine.

Timezones enter through an `OffsetResolver` callback rather than a fixed number,
so a DST transition is expressible in a test: on 2026-03-29 a European local day
is 23 hours long and a ledger assuming 24 loses or double-counts an hour.

## Spec contradiction found: the weekly challenge

Tally's plan says under *Suggested tasks*: "**Weekly challenge:** accept and
complete 3 suggested tasks in a week for a **bonus credit**." Credit means
minutes.

That predates settled decision 12, added when the app was rescoped: **ticking a
task earns nothing, only timed focus earns.** A weekly challenge paying minutes
for completing self-reported tasks reintroduces exactly the farmable path that
decision closed.

Resolved the way the rest of the design already assumes: **the weekly challenge
pays a sticker, not minutes.** `ASSET-PROMPTS.md` already lists a `challenge`
rosette with the rule "Complete the weekly challenge", so the sticker version
was the intended one and the word "credit" is a leftover. The plan text needs
correcting; nothing in code implements the minutes version.

## The day layer cannot pay the ledger, by type

`TodayPlanner` and `LedgerEngine` share no type that carries credit.
`TodayView` exposes the user's own estimate in seconds and nothing creditable;
`complete()` returns a `StickerStamp` or nothing. There is no code path from a
checkbox to the balance because there is no vocabulary for one. That is cheaper
to maintain than a test asserting a negative, though `today_planner_test.dart`
asserts it too.
