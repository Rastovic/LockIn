/// The second currency.
///
/// Completion pays a sticker; only timed focus pays minutes. **No sticker ever
/// grants minutes, grace, debt relief, savings or a treat** - the same rule
/// that guards rewarded ads, extended to cover these. Nothing in this file
/// imports the ledger, which is how that stays true.
library;

enum StickerTier {
  /// Always available. A label the user puts on a task.
  base,

  /// Earned once, kept forever, and restored from a backup rather than
  /// re-earned.
  unlockable,
}

/// Everything the unlock rules can ask about, derived from history.
///
/// Recomputed on every call, never stored as a flag. A restored backup rebuilds
/// the right collection from the imported rows instead of trusting a boolean
/// that might have been written by a buggy version.
final class UnlockContext {
  const UnlockContext({
    this.bestSolvencyStreak = 0,
    this.cleanWeeks = 0,
    this.cleanMonths = 0,
    this.largestDebtClearedMinutes = 0,
    this.phoneDownBlocks = 0,
    this.longestPhoneDownMinutes = 0,
    this.phoneDownBefore9am = false,
    this.phoneDownAfter9pm = false,
    this.treatCount = 0,
    this.largestTreatMinutes = 0,
    this.peakSavingsMinutes = 0,
    this.dreadCleared = 0,
    this.dreadCleared30Days = false,
    this.dreadCleared90Days = false,
    this.sameDayDreadStart = false,
    this.clearedAllDread = false,
    this.sessionCount = 0,
    this.longestSessionMinutes = 0,
    this.startedBefore7am = false,
    this.startedAfter10pm = false,
    this.bestWeekFocusMinutes = 0,
    this.bestHabitStreak = 0,
    this.fullDays = 0,
    this.fullWeekRun = 0,
    this.planningStreak = 0,
    this.challengesCompleted = 0,
    this.daysSinceInstall = 0,
  });

  final int bestSolvencyStreak;
  final int cleanWeeks;
  final int cleanMonths;
  final int largestDebtClearedMinutes;

  final int phoneDownBlocks;
  final int longestPhoneDownMinutes;
  final bool phoneDownBefore9am;
  final bool phoneDownAfter9pm;

  final int treatCount;
  final int largestTreatMinutes;
  final int peakSavingsMinutes;

  final int dreadCleared;
  final bool dreadCleared30Days;
  final bool dreadCleared90Days;
  final bool sameDayDreadStart;
  final bool clearedAllDread;

  final int sessionCount;
  final int longestSessionMinutes;
  final bool startedBefore7am;
  final bool startedAfter10pm;
  final int bestWeekFocusMinutes;

  final int bestHabitStreak;
  final int fullDays;
  final int fullWeekRun;
  final int planningStreak;
  final int challengesCompleted;
  final int daysSinceInstall;
}

/// One sticker.
final class Sticker {
  const Sticker({
    required this.id,
    required this.tier,
    required this.subject,
    this.rule,
    this.unlockedBy,
  });

  final String id;
  final StickerTier tier;

  /// What the artist draws. Mirrors `apps/13-tally/ASSET-PROMPTS.md`.
  final String subject;

  /// The unlock rule in the exact words shown on the locked silhouette.
  ///
  /// **No mystery unlocks.** This app's voice is a friend with a spreadsheet,
  /// and a friend with a spreadsheet does not make you guess.
  final String? rule;

  final bool Function(UnlockContext)? unlockedBy;

  bool isUnlocked(UnlockContext context) =>
      tier == StickerTier.base || (unlockedBy?.call(context) ?? false);
}

/// The closed list of sixty.
///
/// **Adding a sixty-first is a Phase 9 decision, never a mid-build one.** This
/// is the guardrail `12-grove` did not have: it drowned in 120 hand-generated
/// assets with no point at which anyone was allowed to stop.
final class StickerCatalog {
  const StickerCatalog._();

  /// Twenty-four categories, always available, never locked.
  static const List<Sticker> base = [
    Sticker(id: 'cleaning', tier: StickerTier.base, subject: 'spray bottle and cloth'),
    Sticker(id: 'dishes', tier: StickerTier.base, subject: 'stack of two plates and a mug'),
    Sticker(id: 'laundry', tier: StickerTier.base, subject: 'folded stack of clothes'),
    Sticker(id: 'gym', tier: StickerTier.base, subject: 'dumbbell'),
    Sticker(id: 'run', tier: StickerTier.base, subject: 'running shoe'),
    Sticker(id: 'stretch', tier: StickerTier.base, subject: 'rolled yoga mat'),
    Sticker(id: 'walk', tier: StickerTier.base, subject: 'footprint pair'),
    Sticker(id: 'study', tier: StickerTier.base, subject: 'open book with a pencil'),
    Sticker(id: 'read', tier: StickerTier.base, subject: 'closed book'),
    Sticker(id: 'write', tier: StickerTier.base, subject: 'fountain pen nib'),
    Sticker(id: 'work', tier: StickerTier.base, subject: 'closed laptop'),
    Sticker(id: 'admin', tier: StickerTier.base, subject: 'sealed envelope'),
    Sticker(id: 'money', tier: StickerTier.base, subject: 'coin stack'),
    Sticker(id: 'call', tier: StickerTier.base, subject: 'telephone handset'),
    Sticker(id: 'shopping', tier: StickerTier.base, subject: 'shopping basket'),
    Sticker(id: 'cooking', tier: StickerTier.base, subject: 'saucepan with a lid'),
    Sticker(id: 'plants', tier: StickerTier.base, subject: 'potted leafy plant'),
    Sticker(id: 'pets', tier: StickerTier.base, subject: 'paw print'),
    Sticker(id: 'selfcare', tier: StickerTier.base, subject: 'bar of soap with a bubble'),
    Sticker(id: 'sleep', tier: StickerTier.base, subject: 'crescent moon with one star'),
    Sticker(id: 'social', tier: StickerTier.base, subject: 'two speech bubbles'),
    Sticker(id: 'creative', tier: StickerTier.base, subject: 'paint brush with a dab'),
    Sticker(id: 'music', tier: StickerTier.base, subject: 'eighth note'),
    Sticker(id: 'outdoors', tier: StickerTier.base, subject: 'mountain with a sun'),
  ];

  /// Thirty-six earned, each by one concrete milestone.
  static final List<Sticker> unlockable = [
    // Solvency
    _u('solvent_7', 'small green sprout', 'End 7 days in a row at zero or above',
        (c) => c.bestSolvencyStreak >= 7),
    _u('solvent_30', 'leafy branch', 'End 30 days in a row at zero or above',
        (c) => c.bestSolvencyStreak >= 30),
    _u('solvent_100', 'small tree', 'End 100 days in a row at zero or above',
        (c) => c.bestSolvencyStreak >= 100),
    _u('clean_week', 'calendar with a tick', 'Go a whole week without borrowing',
        (c) => c.cleanWeeks >= 1),
    _u('clean_month', 'calendar with a ribbon', 'Go a whole month without borrowing',
        (c) => c.cleanMonths >= 1),
    _u('dug_out', 'shovel', 'Clear a debt of 30 minutes or more',
        (c) => c.largestDebtClearedMinutes >= 30),
    // Phone-down
    _u('facedown_1', 'phone lying face down', 'Finish your first phone-down block',
        (c) => c.phoneDownBlocks >= 1),
    _u('facedown_10', 'phone under a blanket', 'Finish 10 phone-down blocks',
        (c) => c.phoneDownBlocks >= 10),
    _u('facedown_50', 'phone with a plant growing over it',
        'Finish 50 phone-down blocks', (c) => c.phoneDownBlocks >= 50),
    _u('quiet_hour', 'hourglass', 'Do a single phone-down block of 60 minutes',
        (c) => c.longestPhoneDownMinutes >= 60),
    _u('morning_quiet', 'sunrise over a phone',
        'Finish a phone-down block before 9am', (c) => c.phoneDownBefore9am),
    _u('night_quiet', 'moon over a phone',
        'Finish a phone-down block after 21:00', (c) => c.phoneDownAfter9pm),
    // Treats
    _u('treat_1', 'wrapped sweet', 'Treat yourself once', (c) => c.treatCount >= 1),
    _u('treat_5', 'small gift box', 'Treat yourself five times',
        (c) => c.treatCount >= 5),
    _u('treat_big', 'party popper', 'Spend 5 hours of savings on one treat',
        (c) => c.largestTreatMinutes >= 300),
    _u('saver', 'piggy bank', 'Reach 10 hours of savings',
        (c) => c.peakSavingsMinutes >= 600),
    _u('saver_big', 'safe with a dial', 'Reach 50 hours of savings',
        (c) => c.peakSavingsMinutes >= 3000),
    // Avoided things
    _u('dread_1', 'mountain with a flag',
        'Finish something you had avoided for 30 days', (c) => c.dreadCleared30Days),
    _u('dread_90', 'mountain with a sunrise',
        'Finish something you had avoided for 90 days', (c) => c.dreadCleared90Days),
    _u('dread_5', 'five small flags', 'Finish five avoided things',
        (c) => c.dreadCleared >= 5),
    _u('first_step', 'single boot print',
        'Start an avoided task within a day of adding it', (c) => c.sameDayDreadStart),
    _u('inbox_zero', 'empty tray', 'Clear every avoided task at once',
        (c) => c.clearedAllDread),
    // Focus
    _u('focus_1', 'tiny stopwatch', 'Finish your first focus session',
        (c) => c.sessionCount >= 1),
    _u('focus_50', 'stopwatch with a ring', 'Finish 50 focus sessions',
        (c) => c.sessionCount >= 50),
    _u('focus_500', 'stopwatch with a crown', 'Finish 500 focus sessions',
        (c) => c.sessionCount >= 500),
    _u('long_haul', 'mug with steam', 'Focus for 2 hours in one block',
        (c) => c.longestSessionMinutes >= 120),
    _u('early_bird', 'bird on a branch', 'Start a session before 7am',
        (c) => c.startedBefore7am),
    _u('night_owl', 'owl', 'Start a session after 22:00',
        (c) => c.startedAfter10pm),
    _u('ten_hours', 'filled bar', 'Focus for 10 hours in one week',
        (c) => c.bestWeekFocusMinutes >= 600),
    // Habits and the day layer
    _u('habit_7', 'chain of seven links', 'Keep a habit for 7 days',
        (c) => c.bestHabitStreak >= 7),
    _u('habit_30', 'chain with a clasp', 'Keep a habit for 30 days',
        (c) => c.bestHabitStreak >= 30),
    _u('full_day', 'checklist, all ticked',
        'Finish everything you planned for a day', (c) => c.fullDays >= 1),
    _u('full_week', 'week grid, all ticked',
        'Finish everything you planned, five days running', (c) => c.fullWeekRun >= 5),
    _u('planner', 'pinned note', 'Plan your day 30 days in a row',
        (c) => c.planningStreak >= 30),
    _u('challenge', 'rosette', 'Complete the weekly challenge',
        (c) => c.challengesCompleted >= 1),
    _u('year_one', 'candle on a cake', 'Use lockIn for a year',
        (c) => c.daysSinceInstall >= 365),
  ];

  static List<Sticker> get all => [...base, ...unlockable];

  static Sticker? byId(String id) =>
      all.where((s) => s.id == id).firstOrNull;

  static Sticker _u(
    String id,
    String subject,
    String rule,
    bool Function(UnlockContext) unlockedBy,
  ) =>
      Sticker(
        id: id,
        tier: StickerTier.unlockable,
        subject: subject,
        rule: rule,
        unlockedBy: unlockedBy,
      );
}

/// Derives which stickers are unlocked.
///
/// Pure and total: the same context always yields the same set, and unlocking
/// is monotonic in every input, so a sticker once earned cannot be taken away
/// by later activity.
final class UnlockEngine {
  const UnlockEngine();

  Set<String> unlockedIds(UnlockContext context) => {
        for (final sticker in StickerCatalog.all)
          if (sticker.isUnlocked(context)) sticker.id,
      };

  /// Stickers unlocked by [after] that were not unlocked by [before].
  ///
  /// Drives the unlock moment: a quiet sheet, one sticker, the rule it
  /// satisfied, dismiss. No confetti, no sound, no exclamation mark.
  List<Sticker> newlyUnlocked(UnlockContext before, UnlockContext after) {
    final was = unlockedIds(before);
    return [
      for (final sticker in StickerCatalog.unlockable)
        if (!was.contains(sticker.id) && sticker.isUnlocked(after)) sticker,
    ];
  }

  /// Locked stickers, each carrying the rule to show under its silhouette.
  List<Sticker> locked(UnlockContext context) => [
        for (final sticker in StickerCatalog.unlockable)
          if (!sticker.isUnlocked(context)) sticker,
      ];
}
