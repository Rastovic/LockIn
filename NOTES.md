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

## The suggestion picker must not use String.hashCode

The day's suggestion is derived from `(dayKey, installId)` rather than stored,
so it survives a reinstall-from-backup and matches between the app and its
widget without a shared table. That only works if the hash is stable.

Dart makes no promise that `String.hashCode` is stable across runs, platforms
or SDK versions. Using it would mean the suggestion silently changing on an app
update, or the widget and the app disagreeing about what today's suggestion is,
a bug that would be very hard to see and very easy to ship. `stableHash` is
FNV-1a over UTF-16 code units, masked to 32 bits, and it is the seed for
everything that must look random and stay put.

## Sticker unlocks are monotonic, and that is load-bearing

Every unlock rule is a `>=` against a historical maximum or a latching boolean,
never a test of current state. So a user who reaches a 30-day solvency streak
and then breaks it keeps `solvent_30`. Taking a sticker away would be the
cruellest possible reading of an app whose whole stance is that nothing is ever
blocked and nothing punishes.

`stickers_test.dart` asserts monotonicity directly, and also asserts that a
fully-maxed context unlocks all 60: an unreachable rule would mean an asset
drawn for nobody.

## macOS TCC blocked ~/Documents mid-session (2026-08-10)

Access to `~/Documents`, `~/Desktop` and `~/Downloads` vanished mid-build with
`Operation not permitted`, from both the shell and the editor tools, while
`$HOME` and `~/git` stayed fine. Those three are exactly the TCC-protected
folders, so it was a privacy grant rather than file permissions.

Fixed by granting the host terminal (iTerm) access under System Settings ->
Privacy & Security -> Files & Folders. Nothing was lost: the files were already
written and the suite was green before the block. Worth knowing if it recurs,
because the failure looks like disk corruption and is not.

## `vitals_archive` is pure Dart; the SAF wrappers are not in it

`DATA-PORTABILITY.md` lists SAF create/open-document wrappers as part of this
package. Those need Flutter. Keeping the package pure Dart means the whole read
path, the conflict rule, the checksum verification and the import preview are
testable without a device or an emulator, which is most of the risk. The
document-picker layer will sit above it as a thin Flutter shim, and on iOS that
same shim is `UIDocumentPicker` with no change below it.

## ZipDecoder does not throw on arbitrary bytes

It returns an empty archive. Caught by the "random bytes are not mistaken for a
backup" test: the file was correctly refused, but with `missingFile` and the
message "this backup has no manifest". For a user who picked a photo by
mistake, that reads as data loss rather than as the wrong file. `ArchiveReader`
now treats a zip containing zero files as malformed.

## Conflict resolution has a deterministic tiebreak

Last-writer-wins on `updatedAt`, tombstone wins a tie. A true tie between two
live rows with the same `updatedAt` breaks on `installId`, so two devices
merging the same pair in opposite order converge on the same answer rather than
ping-ponging forever. This matters only for merge-mode import and a future
`POST /sync`, neither of which ships in v1, but the rule has to be decided
before rows are written or the data cannot support it later.

## drift_dev is pinned below 2.34.1, and the reason is the workspace

From 2.34.1, `drift_dev` requires `analyzer ^13.0.0`. The Flutter SDK pins
`flutter_test -> test_api 0.7.11`, which caps `test` at a version needing
`analyzer <13`. A pub workspace has **one shared resolution**, so one package's
build-time dependency can break every other package's tests.

`drift_dev: '>=2.33.0 <2.34.1'` is the last version on the compatible side.
Revisit when Flutter's bundled `flutter_test` moves to analyzer 13; the runtime
`drift` dependency is unconstrained and stays current.

## `Meta` is not a usable drift table name

A table class called `Meta` fails codegen with "the referenced element, Meta, is
not understood by drift" - it collides with the annotation class in
`package:meta`. Renamed to `AppMeta` with `@DataClassName('AppMetaRow')`; the
SQL table is still `meta`, so the archive format is unaffected.

Also: in a drift table file the `library;` directive must come **before** the
imports, or the analyzer rejects the file with a message that does not mention
directive order.

## The import preview was looking for the wrong column name

`ImportPlanner.preview` searched rows for a `dayKey` column. Drift writes
`day_key`. The synthetic archive tests hand-wrote `dayKey` and passed, so the
bug only surfaced in the first test that exported a real database.

The effect was silent and bad: the date range vanished from the confirmation
sheet, so the user would have been asked to confirm wiping their history with no
statement of what period was about to be replaced. It now accepts both names.

Worth remembering as a pattern - the unit tests agreed with each other because
they shared my wrong assumption. Only the round-trip against a real schema
disagreed.

## Spend must be stored as spans, not as a per-day total

Found by the first test that ran the engine against real stored rows, and it is
a genuine schema-design bug rather than a test artifact.

`day_spend` originally held one row per app per day, holding a total. Feeding
that back into the engine loses **when** the spend happened, and the ledger is
order-sensitive: grace fires once per zero-crossing, so the same 55 minutes
spent before or after a 40 minute session close at different balances - 20
versus 15, with grace consumed in one case and untouched in the other.

A per-day total silently places every minute at the day's open. That would have
made "recompute from a checkpoint always gives the same balance" false in a way
no unit test on the engine alone could catch, because the engine was correct
throughout.

Now `spend_spans` holds merged billable spans with real timestamps and is the
recompute input; `day_spend` is a derived read-model rebuilt from it, kept only
so the Statement's per-app breakdown is one indexed read rather than a scan.
`ledger_repository_test.dart` pins both answers so the distinction cannot be
optimised away later.

## Three more name collisions worth knowing

- drift generates a data class per table, so `Treats` yields `Treat`, which
  collides with the engine's domain type. Every table with a domain twin now
  carries `@DataClassName('...Row')`. A persistence row is not a domain object
  and should not have been sharing a name anyway.
- drift exports `VerificationResult`. `vitals_archive`'s type is now
  `ImportVerification`, which is more specific regardless.
- drift exports `isNull` and `isNotNull` as query builders, which shadow the
  matchers in every test importing both. Test files use
  `import 'package:drift/drift.dart' hide isNull, isNotNull;`.

## The library's tone rules are tests, not intentions

`library_content_test.dart` checks the shipped copy the way the code is
checked: every reason is exactly one sentence, no exclamation marks anywhere,
no self-help vocabulary from an explicit banned list ("journey", "mindset",
"you've got this", "small wins"), no guilt vocabulary, no reason opening by
addressing the reader, and every reason distinct.

The plan is unusually strict about this - the library "is not a motivational
quote engine and it ships zero quotes", and the voice is a friend with a
spreadsheet. That kind of rule erodes one well-meaning edit at a time, and it
erodes invisibly. Mechanising it costs an afternoon and holds for the life of
the app.

Two content rules that turned out to be correctness rules rather than style:

- **Every suggested item uses a base sticker, never an unlockable one.** A
  suggested task wearing a locked sticker shows an empty square on day one,
  which reads as a broken app rather than as something to earn.
- **No item is under the five minute earning floor.** An item that cannot earn
  teaches the user that the timer does not work.

There is also a test that runs the real picker over 365 days against the real
library and asserts a suggestion is available on every one of them. Forty items
against a thirty day repeat window is comfortable, but it is the kind of margin
worth pinning rather than assuming.

## Notification policy is pure; only one file touches the plugin

`NudgePolicy` holds every rule worth arguing about - daily caps per kind,
cooldowns by tag, quiet hours, what happens when permission is refused - and is
pure Dart, so all of it is tested without a device. `LocalNotifier` is the only
file importing `flutter_local_notifications`.

Three rules that are easy to get wrong and are pinned by tests:

- **A batch consumes its own budget as it goes.** Three nudges queued in one
  reconcile would otherwise each check a cap none of them had consumed yet, and
  all three would fire.
- **The cap resets at the app's 04:00 day boundary, not at midnight.** A nudge
  at 02:00 belongs to yesterday and must not get a fresh budget.
- **Quiet hours crossing midnight is one window, not two**, and it is judged in
  local time. Judging by UTC would nudge someone at midnight in one zone and
  treat 21:00 as quiet in another.

A reminder the user scheduled is never capped, never held for quiet hours and
never deduplicated. Silently dropping something someone explicitly set is a
broken app, not a considerate one.

Android scheduling uses `inexactAllowWhileIdle`, which keeps the app off
Android 14's `SCHEDULE_EXACT_ALARM`. That permission needs a special-access
grant and a Play declaration, nothing here needs second precision, and asking
for exact alarms in order to nudge someone about scrolling would not survive
review.

## Blush had the exact failure its own rule was written to prevent

The plan says: "which is why Blush's borrowing is a deep crimson and not another
pink". Both Blush sets shipped a borrowing colour that was, in fact, another
pink - `#FF6B85` in dark and `#A81B3B` in light, sitting 104 and 99 perceptual
units from their own solvent colour. Close enough to be confused at a glance.

Caught by the distinguishability test, and only after that test was fixed, which
is the more interesting half:

**The first version measured WCAG contrast, which is the wrong tool.** Contrast
is a luminance ratio. Mint `#4FE3A1` and amber `#FFC24B` score 1.02 on it and
are in no danger of being mistaken for one another. Contrast answers "can text
be read on this ground"; it says nothing about whether two signal colours look
alike. The test now uses a redmean perceptual distance with a floor of 120.

Blush dark borrowing is now `#FF5252` (190 units) and Blush light `#B81E1E`
(133). Both stay warm enough to belong to the palette while reading as red
rather than pink. The light one matters more than the rest: Blush is the theme
the store listing is shot in.

## Theme changes animate, which hides token bugs in tests

`MaterialApp` animates a `ThemeData` change, and `TallyTokens.lerp` swaps
wholesale at the halfway point rather than blending. A widget test that reads a
colour straight after `pumpWidget` therefore reads the *previous* theme's token
and every theme looks identical. `pumpAndSettle` first. Worth knowing because
the symptom - "all three themes render the same colour" - looks exactly like the
hardcoded-colour bug the test was written to catch.

## Row layout and the done control, revised at review

Both controls now sit together on the right: grip, sticker, title, estimate,
then the done dot and the play button. Grouping them lets the sticker and title
read as one unit starting near the left edge.

The done control lost its tick glyph. The row already says done three ways -
the title is struck through, dimmed, and the sticker has stamped - so a check
mark was a fourth signal and the loudest of them. It is now a 1px ring that
fills solid. **A plan should not read like a form.**

Hit targets stayed at 44pt around 16pt visuals. Making a control quieter must
not make it harder to hit.

## Semantics with text children swallow their own label

`_OfferedHabit` wrapped a `Semantics(button: true, label: ...)` around a row
containing `Text` widgets. The Text nodes produce their own semantics, which
compete with the parent's label, and `find.bySemanticsLabel` found nothing -
meaning a screen reader would not have found the button either.

Fixed with `excludeSemantics: true`, which is correct here because the label
fully describes the control and the visible text is redundant with it. Worth
remembering: a Semantics label on a container of text is not automatically the
node a screen reader lands on.

## ReorderableListView.onReorder reports an insertion index

`onReorder` gives a destination one higher than the final position when
dragging downwards; `onReorderItem` (Flutter 3.41+) reports a final position and
is what `TodayPlanner.reorder` expects. Using the newer callback removes the
correction entirely rather than hiding an off-by-one in the UI layer. The old
one is deprecated, which is how this surfaced.

## Testing does not involve Play at all

Play is for distribution. Everything below runs the real app with no store, no
account and no review:

- `cd apps/tally && flutter run -d chrome` - the fastest look. Flutter draws its
  own pixels, so a web build is a faithful preview of the layout.
- `flutter run -d <emulator>` - a real Android device image.
- `flutter run -d <phone>` over USB with developer mode on. This is the only way
  to judge the live ticker, which is the signature interaction and the one thing
  no static image can show.
- `flutter build apk` then `adb install` - a real installable build, still no
  store involved.
- `flutter test --update-goldens --tags golden` then look at
  `packages/tally_ui/test/goldens/`.

`apps/tally` currently runs a preview harness rather than the shipping app:
the real screens, driven by the real engines, over a fixed Tuesday instead of a
database. Theme, brightness and balance state are switchable from a side panel
on a wide window.

## Goldens need a real font loaded or they are unreadable

`flutter test` ships a placeholder font that draws every glyph as a filled box.
That is fine for catching a moved pixel and useless for judging copy, which is
what these images are for. `golden_test.dart` loads a system TTF in `setUpAll`
and falls back silently when it is absent, so CI on another machine still gets a
valid baseline.

Emoji and Material icons still render as boxes, because the substituted font has
neither. Not worth chasing: both render correctly on a device.

## The day header overflowed, and a golden is what showed it

The header was `Row(Text, Spacer, Text)`. Two unflexible children either side of
a Spacer overflow rather than yield, so at 2x text it ran 266 pixels past the
edge - and the striped overflow banner was visible in the very first golden.

`DESIGN-SYSTEM.md` requires Dynamic Type to 200%, so this was a real defect
rather than a test artifact. It is now a `Wrap`, which drops the planned total
to a second line instead. `today_screen_test.dart` runs the screen at 1x, 1.5x
and 2x and fails on any overflow, because a RenderFlex overflow throws in a
test.

The balance strip had the same shape and was fixed alongside it: the unit label
and the streak pill are both `Flexible` now, and the strip has a minimum height
rather than a fixed one.

## Three fixes from looking at the running app

**1. `mainAxisAlignment: spaceBetween` was a self-inflicted regression.** Added
while fixing the Dynamic Type overflow, it spreads *every* child apart, not
just the last one, so the dot, the number and "min left" drifted away from each
other. The left cluster is now one `Expanded` Row with `mainAxisSize.min`, so
its internal spacing is fixed and only the gap before the streak pill absorbs
leftover width. Overflow safety is unchanged.

**2. The glow took three attempts, and each failure was informative.**

A blurred rectangle inside a clipping Stack turns its soft edge into a hard one,
so it read as a green box rather than a halo. Letting it escape with
`Clip.none` then put a haze outside the widget's own bounds, visible past the
phone frame.

A plain `RadialGradient` sized to the strip drew a small blob instead of a band,
because **`RadialGradient.radius` is a fraction of the box's shortest side** -
at 64 tall, a radius of 0.5 is 32 pixels however wide the box is.

The shape that works: a true circle that fades to nothing at its own edge,
scaled on one axis. Soft on every side, contained inside the strip, and no
composited blur layer per frame.

**3. Graphite was cut.** Seen next to Aurora it was the same theme with a
different neutral. A theme picker earns its place by making the app feel
different, not by adding a row. Two themes now: Aurora (default, dark, mint)
and Blush (warm, pink, the listing theme). That also removes a third of the
golden set and a third of the contrast surface to maintain.

None of these were visible in a passing test suite. All three came from looking
at a picture.

## The native usage spike

`apps/tally/android/.../UsageReader.kt` reads `UsageStatsManager.queryEvents`
and returns closed, merged foreground spans over one method channel.
`lib/platform/android_usage_source.dart` is the only file in the app that knows
Android exists, behind the `UsageSource` interface in `tally_engine`.

Two things are deliberately done in Kotlin rather than Dart:

- **Malformed event handling.** Unpaired resumes, orphan pauses, repeated
  resumes and out-of-order events are all normal input. Handling them at the
  source means the iOS implementation is not obliged to reproduce Android's
  quirks.
- **Merging overlapping spans.** Picture-in-picture puts two watched apps in
  front at once, and a minute of the user's life is one minute however many
  apps were on screen. Doing it in the source makes it a guarantee every
  implementation owes rather than a step a caller can forget.

`UsageSource` is shaped around the question - what did this user spend, which
apps can I offer - rather than around `queryEvents`, because iOS cannot answer
the second question at all and an interface shaped like `UsageStatsManager`
would have to be torn up to add it.

Every channel failure is answered rather than thrown. A tracker whose numbers
vanish because a call went wrong is worse than one that reports nothing.

**The spike is written and the APK builds, but it has not been run.** Nothing
about it is proven until the numbers are held next to Digital Wellbeing on a
real phone, which is what `UsageSpikeScreen` exists for.

## The emulator needs an x86_64 image on this machine

`flutter doctor` reports `darwin-x64`: this is an Intel Mac. An arm64 system
image installs happily and then fails at launch with "Avd's CPU Architecture
'arm64' is not supported by the QEMU2 emulator on x86_64 host". Check the host
architecture before choosing an image.

An emulator is useful for layout and for permission flows. It is **not** useful
for the usage spike: there is no real app usage on a fresh emulator to compare
against, so the numbers are all zero and prove nothing.

## The emulator is not worth fighting on this machine

An x86_64 image boots, but with `swiftshader_indirect` software rendering it
takes four minutes to boot and `adb shell` hangs under load. A debug APK sat on
the Flutter splash indefinitely; the package service eventually stopped
responding entirely.

What it did establish, which is worth having: **the APK builds, installs and
launches on Android** - `topResumedActivity` confirmed `com.jelena.tally/.MainActivity`.
So the Kotlin links, the manifest is valid and the app starts.

For anything beyond that, use the phone. It is faster, it is the real target,
and the usage spike is meaningless without real app usage to compare against.
A release APK is at `apps/tally/build/app/outputs/flutter-apk/app-release.apk`
and can be side-loaded directly.

## A Semantics label on a container of text swallows itself

Bitten twice now, so it is a pattern rather than an incident.
`Semantics(button: true, label: ...)` wrapped around a subtree containing `Text`
produces competing nodes, the parent's label never forms, and the control is
unreachable by name. Widget tests find nothing - and neither would a screen
reader.

`excludeSemantics: true` is the fix wherever the label fully describes the
control and the visible text is redundant with it. That is true of every button
in this app: "Add 5 minutes" says more than "+5".

## The focus timer is wall-clock, and that is not a detail

`FocusRun` derives everything from `startedAt`, its pauses, and the instant it
is asked about. The UI's one-second ticker decides *when* to repaint, never
*what* the number is.

A tick-accumulated timer would be wrong in both directions: Flutter stops
delivering timer callbacks when the app is backgrounded, so a 25 minute block
spent with the screen off would credit a fraction of it; and a timer that keeps
firing while the phone sleeps can be made to credit more than was worked.

Paused time is removed by **shortening the session span** handed to the ledger,
rather than by passing the real end instant. The engine therefore credits only
seconds actually focused and needs to know nothing about pausing.

## Two harness lessons from the task sheet

**The default test viewport is landscape 800x600.** That is not a shape this app
ever runs in, and a bottom sheet behaves nothing like it does on a phone -
controls land off-screen, taps miss, and `ensureVisible` does not do what you
expect. Sheet tests now set a 390x844 viewport, and the failures went away
because the sheet was finally being asked the question it was designed for.

**A sheet must scroll.** The task sheet is taller than a small phone once the
keyboard is up, and a sheet that clips its own save button is unusable. It is a
`SingleChildScrollView` capped at 90% of screen height. Found by a test, but it
would have been found by the first user with a small phone.

## Manage Tasks: the empty states carry the explanation

The four task kinds are the part of this app most likely to confuse, and there
is no tutorial. The only place the difference can be explained is each
segment's empty state, so each one says what its list is *for*: daily tasks
carry a streak, project tasks have no deadlines, avoided things count the days,
and one-offs carry nothing. Those strings are load-bearing rather than
decorative, and there is a test on each.

The segment chips carry counts for the same reason: without them, learning
whether anything is in the other three lists costs three taps.

## Persistence: nothing lives only in memory

`TallyController` writes every mutation through to the database before telling
the UI about it. A planner that loses your day because the OS reclaimed the
process is worse than no planner.

It reloads on `AppLifecycleState.resumed` as well as on open, because the ledger
is derived: whatever happened while the app was away, including a day rolling
over at 04:00, is worked out from stored rows rather than from anything held in
memory.

Two rules that are easy to get wrong and are tested:

- **Stored spend for a day is replaced, never appended.** The usage source
  returns the whole window on every call, so appending would double-count on
  every reconcile - and reconciles run constantly.
- **Habit streaks are derived from the plan, not stored.** A stored counter
  drifts; a derived one cannot. Today not being ticked yet does not break a
  streak, because the day is still running and counting otherwise would punish
  someone for opening the app in the morning.

## drift_flutter had to be 0.3.x

`drift_flutter` 0.2.x pins `sqlite3 ^2.4.6` while `tally_data` already needs
`^3.4.0`, and one shared workspace resolution cannot satisfy both. 0.3.0 is the
first release on the 3.x line.

## The install id must survive a restore

It is generated once into `shared_preferences` and kept. Regenerating it on a
restore would make every row imported from the old phone look like it came from
a different device, which is exactly the information a future merge depends on.

## Balance and the pool

Two rules on the Balance screen that are about honesty rather than layout:

- **Grace is stated only while it is running.** A permanent line saying "5
  minutes of grace" would read as an allowance rather than as the one-off
  per-zero-crossing thing it is.
- **Unrepayable overspend is shown separately from the debt.** Past the -60
  floor the number owed stops growing while the real minutes keep being
  recorded. Folding them together would misstate both: the balance would look
  worse than what has to be repaid, or the overspend would vanish.

The best streak is still shown when the current one is broken. It reads as a
fact rather than a rebuke, and it is the number that says the streak is
reachable again.

Per-app labels come from `watched_apps` rather than from the platform, so an app
uninstalled since it was watched still has a name on the statement instead of a
bare package id.

The pool sheet is **multi-select**: planning a day is one sitting, and closing
and reopening a sheet per task turns a two minute job into a chore. The button
names the count, so the tap is never a guess. Only stickers actually in use are
offered as filters, because a row of all 24 would be mostly options returning
nothing.

## Watched apps owns the rules, and changing one recomputes everything

The plan puts the earn ratio, the allowance, the caps and the day boundary on
this screen rather than in Settings, so there is never a second place to look
for why a number came out the way it did.

Each rule is a row of **choices rather than a free number field**. Every option
offered is one the ledger is known to behave sensibly under; a text box invites
a value that makes the app quietly nonsensical.

Changing a rule rebuilds the controller and recomputes the whole stored history
rather than only today. The ledger is derived from these settings, so changing
the earn rate changes what every past day was worth - leaving old days on the
old rule would make the statement disagree with itself.

Two non-destructive rules, both matching how the schema already behaves:

- **Unwatching sets `removedAt`, it does not delete.** Future counting stops
  from that moment; past statements keep what they already recorded.
- **A watched app since uninstalled stays in the list, marked.** Dropping it
  would silently stop counting something the user chose and leave its history
  unexplained.

Apps sort watched-first, then by how much time they actually cost. Someone
reopening this screen is usually looking for something they already picked.

## Onboarding: the reason before the ask, every time

This is the funnel the product depends on, and usage access is where trackers
die - the plan budgets a 40-60% loss at that step. Two rules shape every screen:

- **The reason is on screen before the ask.** A permission dialog that arrives
  cold is the biggest cause of a refusal that never gets reversed. The usage
  step answers the three things a reasonable person wants to know first:
  nothing is uploaded, only the apps you pick, you can turn it off.
- **Every step can be moved past, and the app says what skipping costs.** A
  funnel that traps someone produces a grant they resent and an uninstall the
  same week.

The button says **"Open Settings"** rather than "Allow", because usage access is
a special app access with no in-app dialog: the user is sent to a system screen
to find a switch. Promising a dialog that never appears makes the app feel
broken at the exact moment trust matters most.

Refusing usage access skips the app picker entirely and goes straight to
notifications. Showing an empty list would be a second dead end in a row.

**Step order differs from the plan.** The plan lists "pick watched apps, grant
usage access". The picker's value is showing each app's own last-week usage, and
that data does not exist until access is granted - asking first would mean a
bare list of names and then a second ask. Access comes first, with its reason
before it.

## flutter_local_notifications needs core library desugaring

It uses `java.time`, which is absent on older Android versions. Desugaring
backports it, and is preferable to raising `minSdk`: the phones that would drop
off are exactly the cheap ones this audience owns.

`isCoreLibraryDesugaringEnabled = true` plus a `coreLibraryDesugaring`
dependency in `android/app/build.gradle.kts`.

## The statement reads rollups, never raw events

A year view is 365 indexed rows rather than a scan over every session and span.
That is the whole reason `day_ledger` exists as a stored derived table.

Missing days are filled in as zero rows rather than left absent. The heatmap
needs one cell per day, and every run-length calculation - longest solvent run,
streaks - breaks silently if a gap is treated as "no day" instead of "a day with
nothing in it". A day with nothing recorded closed at zero, which is solvent.

Every figure carries a comparison against the same-length period immediately
before, because a number with nothing to compare it to is trivia. "Spent" and
"earned" colour their change in opposite directions: more earned is good, more
spent is not.

A focus session with no task attached still appears, as "Unattached focus".
Hiding it would make the earned column disagree with the where-it-came-from
breakdown, and a statement that does not add up is worse than one with an
awkward row in it.

## The watcher delivers notices, it does not keep the count

`BalanceSnapshot` is the seam that makes the plan's architecture rule real.
Dart recomputes the authoritative balance from stored rows and writes it, with
the instant it was true. `WatcherService` subtracts usage since that instant and
nothing more.

The consequence is the one the plan wants: an OEM battery manager can kill the
service for six hours and the numbers are still exactly right the moment the app
is opened. Only the nudge was missed - a degraded experience rather than a
broken product.

Details that matter more than they look:

- **Nudges fire on the crossing, not on the state.** A service polling every
  fifteen seconds would otherwise send "balance empty" a hundred times. Each of
  the three is also marked sent per day, so a restart mid-debt does not re-send
  everything already passed.
- **Polling backs off hard.** Fifteen seconds only while something is actually
  being spent; two minutes otherwise. A tracker that eats the battery gets
  uninstalled whatever its numbers say.
- **The service stops when nothing is watched.** A permanent notification for
  someone who never picked an app is an intrusion with no payoff.
- **`START_STICKY` and a boot receiver.** "Stopped tracking after a reboot" is
  the most common one-star review in this category.
- **A failed poll never takes the service down.** The next one may succeed, and
  the app's numbers do not depend on this running at all.

The `specialUse` declaration is written honestly and states the narrow claim:
the service exists to deliver a notice at the time it is useful, not to do the
counting. That is also the argument a Play reviewer will weigh, and the Phase 1
fallback stands if it is refused - drop the service, poll on WorkManager's
15-minute floor, lose the timely nudge, keep every number correct.

## The sticker sheet closes a promise the app was quietly breaking

Stamps were being written on every completion and shown nowhere. The whole
"completion pays a sticker rather than a minute" design was invisible, which
makes ticking a task feel like it does nothing - the exact impression the
separation of currencies exists to avoid.

The sheet is a page that fills. **No score, no target, no percentage**: adding
one would turn it into another number to fall short of, and the page is already
the feedback.

Unlocks are derived from history on every open rather than stored as flags,
matching the ledger's rule. A restored backup rebuilds the right collection from
imported rows rather than trusting a boolean written by an older version.

Locked stickers show as silhouettes with their rule in plain words. No mystery
unlocks: this app's voice is a friend with a spreadsheet, and a friend with a
spreadsheet does not make you guess.

The sheet sits one tap from the statement rather than in a fifth tab. It is the
same question - what happened - asked in the other currency.

## The treat sheet is the only thing that pays out

Without it the ledger only ever takes minutes away, and savings are a number
that grows and does nothing. The plan calls it the counterweight to the whole
app, and it is right: a ledger that never pays out is a scold with arithmetic.

Three things stated rather than left to be discovered:

- **The minutes are burned, not moved.** The confirmation says so in those
  words, before the button. Someone who thinks the minutes went somewhere will
  feel robbed the first time they look for them.
- **The suggestions are deliberately ordinary and cheap** - lunch, a book, the
  cinema. A list of expensive things would make the reward feel out of reach,
  and the whole point is that it is not.
- **The button only appears when there is something saved.** A treat button over
  an empty pot is an invitation to nothing.

The burn goes through the engine rather than around it: a treat row is written
and the ledger recomputed, so the rule that treated minutes can never return as
scroll time is enforced in the one place that already guarantees it, under a
property test.

## Insights answers a different question, and holds no opinions

The statement answers "what happened". Insights answers "what am I actually
like" - when you start, what you spend focus on, how much was phone-down.

**Every figure is flat.** No targets, no streaks to protect, nothing to fall
short of. A screen about your own patterns stops being useful the moment it
starts having opinions about them, and "you start most often around 9pm" is an
observation the app is in no position to grade.

"Days with nothing logged" is stated without comment for the same reason. Plenty
of them are days that simply did not need the app.

Built from sessions rather than rollups, because these questions are about
individual blocks - the hour one began, how long the longest ran - which a day
total cannot answer. The hour histogram uses **local** time, since "when do I
start" is a question about the user's day and not about UTC.

Both charts are bar series, which is one of the three kinds section 4 of
`DESIGN-SYSTEM.md` allows. The instruction there is explicit - "only three
kinds, don't invent more" - so the histogram is a bar series with fewer labels
rather than a new chart type.

## Goals, export and the theme picker

**Goals are not tasks, and the type says so.** No estimate, no schedule, no
completion that earns anything, and no code path into a day. The card has a
different shape from a task row - an outline rather than a fill - so the two
never read as the same kind of thing. The moment a goal can be ticked it becomes
another thing to fail at.

The one place a goal earns its keep is a linked project, which turns a wish into
something with real hours behind it: "thesis: 62 sessions, 41 hours".

**The CSV says plainly what it is not.** The row in Settings reads "A
spreadsheet to read. Not a backup: it cannot be loaded back in." The archive in
`vitals_archive` is the thing that round-trips, and a user who confuses the two
loses data. Task titles are escaped, because a comma in one would silently shift
every column after it.

Per-app spend is off by default in the export. It names your apps and your worst
numbers, and this is the file most likely to be shared or left in a downloads
folder.

**Theme and brightness live in preferences, not the database.** They describe
this device's look rather than the user's data, so a restored backup does not
repaint the phone it landed on.

Third instance of the drift row-name collision: `Goals` generates `Goal`, which
clashed with the domain type. `@DataClassName('GoalRow')`, same as `TreatRow`
and `TaskRow` before it. Worth doing pre-emptively on any new table whose name
has a domain twin.

## Backup and restore, and the confirmation that guards it

The format, reader and verification were built and tested weeks before this UI.
What this adds is the flow, and the flow is the risky part: this is the screen
where a misunderstanding costs someone a year of history.

- **Nothing is written until the user has seen what is in the file.** The
  confirmation states the counts, the date range, which device made it, and
  that it replaces everything. It is not dismissible by tapping away.
- **A refused file says "nothing on this phone was changed."** That is the
  reassurance that actually matters after a failed restore.
- **Rows that could not be read are named before confirming**, not discovered as
  a gap later.
- **After a restore the imported history is verified by recomputation**, and the
  result is shown rather than logged. It exercises the exporter, the importer
  and the engine at once on real data, and it is free in an app that already
  recomputes.

Export shares rather than saving to a fixed folder: the user picks Drive, email
or a file manager, so the backup lands somewhere they will actually look for it,
and no storage permission is needed.

## Two Android build lessons

**file_picker forced compileSdk 36.** It pulls in
`flutter_plugin_android_lifecycle`, which requires compiling against API 36, and
the failure surfaces in the *plugin's* module rather than the app's. Raising
`compileSdk` changes nothing about which devices the app runs on - `minSdk`
governs that - so nobody is dropped.

**The subprojects hook has to come before `evaluationDependsOn(":app")`.**
Flutter's generated root gradle file forces evaluation there, and an
`afterEvaluate` registered after it throws "Cannot run
Project.afterEvaluate(Action) when the project is already evaluated."

## Bug audit before first full day of use (2026-08-11)

Two real defects, both found by reading the riskiest seams rather than by a
failing test, which is the point: neither had a test that could have caught it.

**Unwatching an app erased what it had already cost that day.** `_storeSpend`
cleared every `spend_spans` row for today and re-inserted only what
`_watchedPackages()` returned, and that getter filters on `watching`. So
unwatching an app at 3pm deleted its morning, and the balance jumped up. The
schema documents the opposite rule in a comment directly above the table:
"Removing an app is not destructive: removedAt stops future counting from that
moment only, and historical spend stays on past statements." Fixed by clearing
only the packages being re-read. Three regression tests in
`tally_data/test/spend_retention_test.dart`, including one that recomputes the
ledger and asserts the unwatched app's minutes still count.

Worth naming the shape of this: the invariant was written down, in the right
place, in plain words, and the code still contradicted it. A comment is not an
enforcement mechanism. The test is.

**A running focus block did not survive process death.** `focus` was an
in-memory field. The wall-clock design means backgrounding is safe, which is
what made this easy to miss - it survives the case you would actually test by
hand. But an OS kill mid-block lost the whole session, and on a cheap phone that
is routine. The 45 minutes really were spent; the app just forgot. Now persisted
to preferences (`FocusStore`) on every transition and restored in `load()`.

Preferences rather than the database on purpose: a block in progress is this
device's transient state, it means nothing on another phone, and it must not
travel in a backup - the same reasoning that keeps `usage_checkpoints` out of
the archive. A restore is stale after 12 hours: something went wrong, and
showing a stale countdown is worse than dropping it quietly. A malformed record
costs the block, never a crash on launch.

**Shipping the APK: macOS firewall, not the code.** The phone's cable is
charge-only, so the APK goes over the LAN. The server was listening and
loopback answered, but the LAN IP timed out. Not a bind or a network problem:
the firewall has Homebrew's python at "Block incoming connections" while
`/usr/bin/python3` is allowed. Same command, different binary, works. Checked
rather than guessed, because the guess would have been "turn the firewall off",
which is a security setting and not mine to change.

## First day of real use (2026-08-12)

Seven things came back. Only one was a wrong number, and it was not the one
that prompted the report.

**The balance was right and unexplained.** −2 borrowing, 66 minutes on one
screen, 67 on another. The ledger reconciled exactly - 60 granted plus 5 of
grace against 67 spent - but no screen said so, and "borrowing" was a word the
app had never defined. Added a "how this adds up" block on the Balance screen
listing the signed terms and totalling to the number in front of it, with the
definition of borrowing placed where the negative number is standing rather
than in a help page nobody opens. The lesson is that correct is not the same as
legible, and a ledger nobody can check is asking to be taken on faith.

**66 versus 67 was real.** The Statement floored the day's seconds, Insights
rounded them. Both defensible, having both indefensible. All formatting now
goes through `tally_ui/lib/src/format/durations.dart`.

While centralising it I changed the rule to truncate towards zero and a test
that already existed caught it: rounding a debt towards zero flatters the
number, which is the one thing this app must never do. The original rule -
floor towards negative infinity, in both directions - was better than my
replacement, and the test was the only thing standing between the change and
the phone. Restored, with the reasoning now written where the operator lives.

**"I did not watch TikTok for an hour."** Unverified, and unverifiable as the
screen stood: a single total is not a claim anyone can check. Each app in
"where it went" now opens to the actual stretches behind its total, from the
`spend_spans` rows the ledger already recomputes from. Either the times match
the afternoon they remember or they do not, and a demonstrably wrong number is
worth more than an unfalsifiable one. Whether the total is accurate is still
open and still the Phase 1 kill gate - the Digital Wellbeing comparison has not
been done.

**Insights and Stickers covered the text.** They were pills floating at
`bottom: 16` in a Stack over the Statement, which scrolled underneath them.
Being reachable only by scrolling to the end of a list is also a poor way to
expose two thirds of a tab. Replaced with a switcher at the top: same space,
never covers content, and shows what else is there before you have read
anything.

**Tasks needed an All.** Four kinds because they are genuinely different
objects, which is still true, but knowing which of four buckets something was
filed under is a poor way to find it again. All keeps the kinds as headed
groups rather than dissolving them, and the tab now opens there.

**Settings scrolled too far.** One flat list: every watched app, then every
rule, then theme, then backup. Reaching Backup meant scrolling past the whole
app list. Now four folded sections, each carrying a one-line summary of its
current state so "what is this set to" is answered without opening anything.

**The Blush light glow read as brick.** It was the borrowing red, and it had to
be: the distinguishability test requires the borrowing colour to sit 120+
perceptual units from the pink solvent, which rules out a pink number. But the
glow is not the number. A colour graded for text makes a bad field - #B81E1E
blurred at half alpha over near-white composites to #DC8A8B, muddy. The glow
now has its own token, #F0607F, which composites to #F8ABBC and sits 68 units
from the solvent glow where the dark red sat 64. Pinker and slightly more
distinguishable, so nothing was traded.

**The sum block did not fit.** Its own test caught a 42px overflow: the Balance
screen was a fixed Column with two Spacers, sized to fit exactly. Anything laid
out to fit exactly breaks the first time someone raises their text size. Now
scrolls.

**Serving the APK: the IP moved.** Yesterday's address was stale - different
network, new DHCP lease. Checked `ipconfig getifaddr` rather than reusing the
address that worked once, which is the same class of mistake as reusing a build
output without checking it was rebuilt.

## Task sheet rework, and the app gets a name (2026-08-12)

**The kind is now a dropdown, and it is usually already right.** It was four
chips, which read as a filter rather than a field and cost a full row to offer
three options nobody was choosing between: tapping "new task" inside Projects
already answers the question. A closed control states the answer in one line.
The kind still inherits from wherever create was tapped, and there is now a
test saying so rather than an assumption.

**Title and description are separate fields.** The old hint for a project task
was "Write the introduction", which was meant as an example of a *title* and
was read as an instruction to write a description. That is a fair reading of a
lone text box with a sentence in it. There is now a labelled title and a
four-line description underneath, and the hint has somewhere to be a hint
about. The description is `tasks.note`, schema 1 to 2, nullable and additive.

Nothing reads the note. That is deliberate and worth keeping deliberate: a
notes field that starts driving behaviour becomes a second, worse task system
inside the first one.

**How long is a wheel.** Seven chips became a wheel from 5 to 120 minutes,
which reads as one continuous quantity rather than seven unrelated buttons. The
floor still holds - nothing under five minutes is offered, because a shorter
estimate would describe a task whose own plan could never earn - and the test
now asserts the floor against the list instead of restating it.

Two real bugs surfaced building it. The wheel's `FixedExtentScrollController`
was constructed in `build`, so every spin rebuilt the sheet, which built a
fresh controller, which reset the wheel mid-gesture; it survived a flick and
dropped the value under a precise drag. And the save button's enabled state was
driven by `markNeedsBuild` on the title field's own element, which rebuilds the
field and not the button above it - it worked only while the field *was* the
whole widget and broke the moment it grew a label. The controller now lives in
the state and the sheet listens to the title properly.

The wheel test drives the controller rather than dragging. A drag lands in a
gesture arena with the sheet's scroll view and the result depends on pixel
distances, which makes the test about Flutter's arena rather than about whether
picking an estimate saves it.

**Choose a sticker is one control now.** It was a small label with a quiet
"Choose" pushed to the far right, which read as two unrelated things. Same size
as before, because size was never the problem: nothing marked it as pressable.
It carries the accent only while empty - once a sticker is picked, the sticker
is the colour on that row and a tinted button beside it would compete with the
thing it just set.

**The app is called lockIn.** User-facing strings only. The applicationId, the
drift filename, the package names and the archive's `appSlug` all stay
`tally`: changing an applicationId orphans every installed copy, and changing
`appSlug` would make the reader refuse every backup already written. A rename
that reaches the wire format is a rename that loses data.

**The icon took four passes, and the proof sheet is why.** Rendering the
foreground under circle, squircle and square masks caught each failure that
reading the code would not have:

1. The art bounding box came out as the entire tile, because the rounded
   corners fade through every colour between the tile and its cream ground, so
   an edge-inclusive scan calls the corners "art".
2. Cut to the tile, the cream corners rode along into the foreground and
   appeared as four white notches inside every mask.
3. Masking the corners transparent left a faint ring: the artwork carries a
   soft highlight just inside its border, which no amount of colour matching
   between the two layers could hide.
4. Cropped inside that highlight, with the background sampled from the artwork
   rather than eyeballed, the seam is gone.

Then the circle mask clipped the speech bubble at 74% and the foreground went
back to the documented 66% band. Four rounds of "it looks fine in the file" and
none of them survived being drawn under a mask.

## Zero allowance, a block alarm, and folds that stay folded (2026-08-13)

**The default allowance is now zero.** It was 30 free minutes a day. Handing
out the app's own currency before the user has done anything makes the first
day a smaller version of the problem rather than the start of the fix, and it
means the number on the strip does not mean the same thing on day one as it
does on day ninety. Still settable for anyone who wants a floor under the day.

The change broke seven tests, all of which were asserting allowance behaviour
while inheriting the allowance from the product default. They now state the 30
they are testing. A test that depends on a default it does not name is a test
that fails whenever someone makes a product decision, and its failure says
nothing about whether the code is correct.

**An alarm at the end of a focus block.** The reason is specific and was worth
hearing: focusing often means using the same phone for the thing being focused
on, so the user leaves this app during a block, and a countdown nobody is
looking at is not a timer. Without an alarm the only way to learn a block had
ended was to come back and check, which defeats the block.

Scheduled as `NudgeKind.scheduled` and quiet-hours exempt: the user started
this timer, so it is never capped by the nudge budget and never held back.
Rescheduled from scratch on every transition rather than adjusted, because
pause, resume and extend all move the end and one cancel-then-set has no
states to get wrong. A block restored after process death gets its alarm back
on load - Android does not keep notifications scheduled by a process that is
gone, so persisting the run without re-arming the alarm would have restored a
countdown that could no longer ring.

Left on inexact scheduling. Exact alarms need `SCHEDULE_EXACT_ALARM`, a
special-access grant and a Play declaration, and the device is not in deep doze
during a study session, so the cost is a possible minute of lateness against a
permission that invites review. Worth revisiting if it turns out to drift.

**A denied permission is now visible.** The permission is checked every time a
block starts, not once at onboarding, because it can be revoked from system
settings at any point. If it is off, the focus screen says so while the block
runs. The whole reason the alarm exists is that people leave this screen - an
alarm that silently cannot ring is worse than no alarm, because it is trusted.

**Settings folds all start closed.** One opened itself when nothing was being
watched. It made the screen open at a different height depending on state, and
an index with a section already unrolled is not an index.

## Projects, quick tasks, and two suggestion bugs (2026-08-14)

**"Not now" was wired to an empty function.** `onDismissSuggestion: (_) {}`,
literally. The card was rebuilt from the same deterministic pick a moment
later, so the button visibly did nothing. There was a `suggestion_history`
table sitting unused the whole time.

**Accepting one did not retire it either**, for a subtler reason: the picker
was called with `addedItemIds: {for (final task in tasks) task.id}` - task
UUIDs compared against library item ids. Two id spaces that never intersect,
so the set was always effectively empty and nothing was ever suppressed. It
type-checked perfectly. Both are `Set<String>`.

Worth naming the shape: the picker had a `history` parameter designed for
exactly this, with suppression rules already written and tested, and the
caller passed neither it nor anything that could work. The engine was right
and nobody connected it. Now the outcome of every suggestion is recorded and
the picker is told, with four tests covering dismiss, accept, no-repeat within
the day, and accept surviving a reload.

**The description never reached the database.** Yesterday's `tasks.note` went
from the sheet to the draft to the model to the column and stopped: the
repository never wrote it and never read it back, so every description anyone
typed vanished on save, silently. A field is not done when it merely compiles
end to end. Fixed with a round-trip test that writes, reads, updates and
clears.

**Projects now hold tasks.** A project is a folder with a name and **no time
of its own**: the header shows what its tasks add up to, derived on the spot.
A stored total would be a second number that starts disagreeing with its own
parts the first time a task changes, which is the entire reason not to have
one.

Deleting a project keeps its tasks - they become unfiled project tasks and are
still listed under their own heading. Someone tidying a project list is not
asking to lose the work inside it, and the confirmation says so before the tap
rather than after.

Opening the sheet from inside a project hides the kind picker: whoever tapped
"add a task" under a project has already answered that question, and offering
to turn it into a habit is offering to lose it.

**Quick tasks are a fifth kind**, and deliberately not habits. A habit carries
a streak, and a streak on taking supplements turns a two second job into
something you can fail at. No streak, no schedule, no estimate - the sheet
hides the wheel entirely for them, because every option it can offer is longer
than the task.

Adding the enum value was the easy part: Dart's exhaustiveness checking found
every switch that needed a new case, which is the argument for switching on
enums rather than defaulting.

Fourth drift row-class collision, after Treat, SavingsTransfer and Goal:
`Projects` generated a `Project` that clashed with the domain type. The rule is
now reflexive - any table whose name matches a domain object needs
`@DataClassName('...Row')` from the start.

## Repeating is a choice, not a kind (2026-08-14, later)

I was part way through making every quick task recur when the better shape
arrived: **repeating is a property of the task, chosen by the user**, not
something inferred from what sort of thing it is.

Inferring it was wrong in both directions. A quick job you only need to do
once had nowhere to go, and nothing of any other kind could repeat at all -
putting the bins out is a dread task that comes back every week whether or not
the app has a category for it. `TaskRepeat { once, daily }` on the task, a
two-option control in the sheet, and the planner asks the task rather than
its kind.

Two options and no more, deliberately. Weekly, monthly and "every third
Tuesday" are a scheduling system, and a scheduling system is the thing this app
is trying not to become. Habits already carry weekdays for the cases that need
them, and a habit is excluded from the repeat control for exactly that reason:
two schedules on one task would disagree.

Schema 2 to 3, nullable, and a null reads as `once` - which is what every task
written before today was.

**Editing a task was dropping fields.** `updateTask` builds a `Task` field by
field from the draft, so every field added to `Task` after that call was
written is silently omitted and nothing fails to compile. `note` was lost on
every edit, and `repeat` would have joined it. `projectId` was being taken from
the original rather than the draft, which meant a task could never be moved.

This is the second time in two days the same class of bug has appeared: a field
added to the model, the column and the sheet, and then quietly not carried by
one of the several hand-written constructor calls in between. The tests now
cover the edit path specifically - rename a task, assert that everything the
rename did not mention survived.

The recurrence test exists in two places on purpose: the planner test proves
the rule, and the controller test proves it survives a write to the database
and a read back the next morning. The first one passing while the second fails
is exactly the shape of the bug that shipped yesterday.

## The home screen widget (2026-08-14, later still)

The original rescope asked for this first - "a widget of all the tasks I plan
to do today… I can see them on that widget" - and it was the one thing from
that message that never got built. Everything else did: the transferable pool,
the manage tab, stickers as categories, the quiet goals list.

**Native, not a plugin.** The app already has a Dart-decides-Android-renders
seam in `BalanceSnapshot`, and the widget follows it exactly: Dart resolves the
titles, the done flags and the sticker glyphs, and Kotlin receives finished
strings. Nothing in the widget knows what a sticker id means, which tasks are
habits, or how a day is assembled. Adding a task kind needs no Kotlin change at
all. A plugin would have added a dependency to re-implement a seam that was
already there.

**Read only, and that is a decision rather than an unfinished edge.** Ticking
from a widget means one of two things: a second writer to the ledger living in
Kotlin, or a background isolate opening the same SQLite file as the running
app. The first duplicates the rules the entire app is built on - the rules that
exist so a checkbox cannot move the balance. The second risks the data. Neither
is worth saving a tap on a list you are about to open anyway. Tapping opens the
app.

Four things that would have been silent bugs on someone's home screen:

- `notifyAppWidgetViewDataChanged` is the **only** thing that makes a
  collection adapter re-read. Sending just the update broadcast leaves
  yesterday's tasks under today's date, which is the worst possible failure for
  a widget: confidently wrong rather than obviously broken.
- The adapter intent needs a **unique data uri per widget id**, or Android
  reuses one adapter across every placed instance.
- Rows need a **pending intent template** on the list plus a fill-in intent per
  row. A click listener set inside the adapter is ignored, and the widget feels
  dead without telling you why.
- A null glyph would render as the literal string "null" in a TextView. The
  Dart side sends an empty string, and there is a test for exactly that.

The widget carries its own small palette in `values` and `values-night` rather
than following the theme picked inside the app. It sits on the user's wallpaper,
not on the app's background: a widget that stayed dark on a light home screen
would look like a hole in it.

It says nothing about minutes until usage access is granted. A confident zero
would read as "you have spent everything" rather than "this is switched off".

Also caught while wiring it: `this._field` inside a **named** parameter list
does not stay named - callers end up passing it positionally. Both injected
dependencies are ordinary named parameters assigned in the initialiser list,
with the lint silenced and the reason written down.

## Widget staleness, and making the accuracy check a real thing (2026-08-14, last)

**Two different kinds of stale, and only one was obvious.**

The minutes standing still while you scroll was the visible one. The fix cost
nothing: `WatcherService` already computes exactly that figure every poll for
the ongoing notification - Dart's authoritative balance minus usage since the
instant Dart wrote it - so it now writes the same number to the widget. No
extra wakeup, no extra usage query, and the widget and the notification can no
longer disagree because they are the same value.

The dangerous one was the day rolling over. Left alone, the widget shows
yesterday's tasks under today's date, which is the worst thing a widget can do:
confidently wrong rather than obviously broken. Kotlin cannot work out when a
day ends - the boundary is a setting, defaults to 4am, and moves with the
timezone - so Dart sends the instant the plan stops being today's and Kotlin
does one comparison. Past it, the list is hidden outright rather than trusted
to be empty, because the adapter still holds yesterday's rows until the app
runs again.

Caught the day flip with `DATE_CHANGED`, `TIME_SET` and `TIMEZONE_CHANGED`,
which are broadcasts Android already sends. Polling on a short period would
have spent battery to learn the same thing later.

**The accuracy check is now a screen instead of a line in a plan.**

Everything in this app is arithmetic on one measurement: how long a watched app
was in the foreground. If that is wrong then the balance, the statement, the
insights and the streak are all confidently wrong together, and no amount of
internal consistency would reveal it. It is the one thing the app cannot check
on itself, and it has been sitting unverified through every feature built on
top of it.

Settings now has "Check the numbers": what lockIn counted per app per day, a
box for what Digital Wellbeing says, and the difference with a plain sentence
naming which way it went. Direction matters and the copy says it - counting
more than the phone over-charges the user, counting less lets spend go
unrecorded, and those are different bugs.

It reads `day_spend`, the stored derived table, and deliberately **not** a
fresh query against `UsageStatsManager`. Re-reading the source would compare
the phone against itself and pass no matter what was wrong with what got
stored.

Readings live in preferences and never travel in a backup: a measurement of
this phone against this phone's own counter means nothing on different
hardware, which is worse than having no reading at all.

Two minutes of disagreement is stated as expected rather than tolerated. It is
the honest resolution of the comparison - the two count session edges
differently and both round - and calling it "close" rather than "wrong" is what
stops the screen crying wolf on its first use.
