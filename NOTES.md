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
