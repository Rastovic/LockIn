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
