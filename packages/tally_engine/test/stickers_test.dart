import 'package:tally_engine/tally_engine.dart';
import 'package:test/test.dart';

const engine = UnlockEngine();

void main() {
  group('the catalog is closed', () {
    test('exactly 60 stickers: 24 base and 36 unlockable', () {
      // The number is a hard cap decided before anything is drawn, not a
      // starting point. A 61st is a Phase 9 decision.
      expect(StickerCatalog.base, hasLength(24));
      expect(StickerCatalog.unlockable, hasLength(36));
      expect(StickerCatalog.all, hasLength(60));
    });

    test('every id is unique', () {
      final ids = StickerCatalog.all.map((s) => s.id).toSet();
      expect(ids, hasLength(60));
    });

    test('every sticker has a subject for the artist', () {
      for (final sticker in StickerCatalog.all) {
        expect(sticker.subject, isNotEmpty, reason: sticker.id);
      }
    });

    test('every unlockable states its rule in plain words', () {
      // No mystery unlocks. Guessing is not this app's voice, and a locked
      // silhouette with no rule under it is just a tease.
      for (final sticker in StickerCatalog.unlockable) {
        expect(sticker.rule, isNotNull, reason: sticker.id);
        expect(sticker.rule, isNotEmpty, reason: sticker.id);
        expect(sticker.unlockedBy, isNotNull, reason: sticker.id);
      }
    });

    test('no base sticker pretends to have a rule', () {
      for (final sticker in StickerCatalog.base) {
        expect(sticker.rule, isNull, reason: sticker.id);
      }
    });

    test('rules read as instructions, not as slogans', () {
      // The tone rule, mechanised: plain and factual, no exclamation marks and
      // no cheering.
      for (final sticker in StickerCatalog.unlockable) {
        expect(sticker.rule, isNot(contains('!')), reason: sticker.id);
      }
    });

    test('byId finds both tiers and misses cleanly', () {
      expect(StickerCatalog.byId('gym')?.tier, StickerTier.base);
      expect(StickerCatalog.byId('focus_1')?.tier, StickerTier.unlockable);
      expect(StickerCatalog.byId('nope'), isNull);
    });
  });

  group('unlocking', () {
    test('a fresh install has the 24 base stickers and nothing else', () {
      final unlocked = engine.unlockedIds(const UnlockContext());
      expect(unlocked, hasLength(24));
      expect(unlocked, contains('cleaning'));
      expect(unlocked, isNot(contains('focus_1')));
    });

    test('a first session unlocks exactly one sticker', () {
      final unlocked = engine.unlockedIds(const UnlockContext(sessionCount: 1));
      expect(unlocked.difference(engine.unlockedIds(const UnlockContext())), {
        'focus_1',
      });
    });

    test('thresholds unlock the tiers below them too', () {
      final unlocked = engine.unlockedIds(const UnlockContext(sessionCount: 500));
      expect(unlocked, containsAll(['focus_1', 'focus_50', 'focus_500']));
    });

    test('one short of a threshold stays locked', () {
      expect(
        engine.unlockedIds(const UnlockContext(bestSolvencyStreak: 29)),
        isNot(contains('solvent_30')),
      );
      expect(
        engine.unlockedIds(const UnlockContext(bestSolvencyStreak: 30)),
        contains('solvent_30'),
      );
    });

    test('newlyUnlocked reports only the difference', () {
      final before = const UnlockContext(sessionCount: 49);
      final after = const UnlockContext(sessionCount: 50);
      expect(engine.newlyUnlocked(before, after).map((s) => s.id), ['focus_50']);
    });

    test('newlyUnlocked can report several at once', () {
      final gained = engine.newlyUnlocked(
        const UnlockContext(),
        const UnlockContext(sessionCount: 60, phoneDownBlocks: 12),
      );
      expect(
        gained.map((s) => s.id),
        containsAll(['focus_1', 'focus_50', 'facedown_1', 'facedown_10']),
      );
    });

    test('nothing is newly unlocked when nothing changed', () {
      const context = UnlockContext(sessionCount: 10);
      expect(engine.newlyUnlocked(context, context), isEmpty);
    });

    test('locked stickers carry the rule the UI shows', () {
      final locked = engine.locked(const UnlockContext());
      expect(locked, hasLength(36));
      expect(
        locked.firstWhere((s) => s.id == 'quiet_hour').rule,
        'Do a single phone-down block of 60 minutes',
      );
    });

    test('unlocking is monotonic: a sticker earned is never lost', () {
      // Every rule is a >= or a latching bool, so more history can only add.
      // A user who earns a 30-day streak and then breaks it keeps the sticker.
      final peak = const UnlockContext(bestSolvencyStreak: 30, sessionCount: 50);
      final later = const UnlockContext(bestSolvencyStreak: 30, sessionCount: 51);
      expect(
        engine.unlockedIds(later).containsAll(engine.unlockedIds(peak)),
        isTrue,
      );
    });

    test('the same context always gives the same set', () {
      const context = UnlockContext(treatCount: 5, peakSavingsMinutes: 700);
      expect(engine.unlockedIds(context), engine.unlockedIds(context));
    });

    test('a full history unlocks everything', () {
      // Proves no rule is unreachable. An unearnable sticker is an asset drawn
      // for nobody.
      const maxed = UnlockContext(
        bestSolvencyStreak: 100,
        cleanWeeks: 5,
        cleanMonths: 2,
        largestDebtClearedMinutes: 60,
        phoneDownBlocks: 50,
        longestPhoneDownMinutes: 60,
        phoneDownBefore9am: true,
        phoneDownAfter9pm: true,
        treatCount: 5,
        largestTreatMinutes: 300,
        peakSavingsMinutes: 3000,
        dreadCleared: 5,
        dreadCleared30Days: true,
        dreadCleared90Days: true,
        sameDayDreadStart: true,
        clearedAllDread: true,
        sessionCount: 500,
        longestSessionMinutes: 120,
        startedBefore7am: true,
        startedAfter10pm: true,
        bestWeekFocusMinutes: 600,
        bestHabitStreak: 30,
        fullDays: 1,
        fullWeekRun: 5,
        planningStreak: 30,
        challengesCompleted: 1,
        daysSinceInstall: 365,
      );
      expect(engine.unlockedIds(maxed), hasLength(60));
      expect(engine.locked(maxed), isEmpty);
    });
  });

  group('the wall between the currencies', () {
    test('an unlock context cannot describe a balance', () {
      // Structural, not asserted: UnlockContext has no field for minutes,
      // grace, debt or spendable credit, and stickers.dart imports nothing
      // from the ledger. A sticker cannot pay out because it has no way to
      // name what it would pay.
      const context = UnlockContext(sessionCount: 500, peakSavingsMinutes: 3000);
      expect(engine.unlockedIds(context), isNotEmpty);
      // peakSavings is an observation of history, never a spendable pot.
      expect(context.peakSavingsMinutes, 3000);
    });
  });
}
