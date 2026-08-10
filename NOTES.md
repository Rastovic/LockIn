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
