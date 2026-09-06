import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_ads/vitals_ads.dart';

/// The app's side of [AdPolicy]: it holds the counters the rules read, keeps
/// them across launches, and is the only thing the UI talks to.
///
/// **Every question has a safe answer before [start] finishes.** The banner
/// asks on the first frame, and a controller that answered "allowed" while
/// still loading would show an ad to a first-run user.
final class AdsController {
  AdsController({AdGateway? gateway, this.policy = const AdPolicy()})
      : gateway = gateway ?? const NoAds();

  final AdGateway gateway;
  final AdPolicy policy;

  static const _sessionCountKey = 'ads.sessionCount';
  static const _coreActionKey = 'ads.coreActionDone';

  AdSession _session = const AdSession(sessionCount: 1);
  bool _coreActionDone = false;
  bool _ready = false;

  /// Set once the user owns the Pro unlock. Wired to RevenueCat later; false
  /// here means the prototype shows what a free user sees.
  bool isPro = false;

  /// Counts this launch, restores the core-action flag, then starts the SDK.
  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_sessionCountKey) ?? 0) + 1;
    await prefs.setInt(_sessionCountKey, count);
    _coreActionDone = prefs.getBool(_coreActionKey) ?? false;

    _session = AdSession(sessionCount: count, coldStartAt: DateTime.now());
    await gateway.initialise();
    _ready = true;
    await _preloadIfEligible();
  }

  /// Fetches an interstitial only for a user who could actually be shown one.
  ///
  /// On a first session, or before the first finished block, this does
  /// nothing: the ad could not be shown however long it waited, and an
  /// unfillable request is counted against the app's match rate.
  Future<void> _preloadIfEligible() async {
    if (!policy.mayPreload(
      session: _session,
      isPro: isPro,
      hasConsent: gateway.hasConsent,
      coreActionComplete: _coreActionDone,
    )) {
      return;
    }
    await gateway.prepareInterstitial();
  }

  /// Records that the user has reached the point of the app at least once.
  ///
  /// In lockIn that is finishing a focus block: before that has happened the
  /// ledger has never paid out, and the app has not yet shown what it is for.
  Future<void> markCoreAction() async {
    if (_coreActionDone) return;
    _coreActionDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coreActionKey, true);

    // The gate the user just passed is the one preloading was waiting on, and
    // the break point is seconds away.
    await _preloadIfEligible();
  }

  /// Whether a banner may be drawn under the current screen.
  ///
  /// [screenBusy] is the caller's answer to rule 4 - a timer running or a text
  /// field on screen - because only the screen knows.
  bool bannerAllowed({bool screenBusy = false}) =>
      _ready &&
      policy.allows(
        placement: AdPlacement.banner,
        session: _session,
        now: DateTime.now(),
        isPro: isPro,
        hasConsent: gateway.hasConsent,
        coreActionComplete: _coreActionDone,
        screenBusy: screenBusy,
      );

  /// Shows a full-screen ad if the caps allow one, and records it if shown.
  ///
  /// Returns nothing the caller has to act on: whether an ad appeared must
  /// never change what the app does next.
  Future<void> maybeShowInterstitial() async {
    if (!_ready) return;
    final now = DateTime.now();
    final refusal = policy.refuse(
      placement: AdPlacement.interstitial,
      session: _session,
      now: now,
      isPro: isPro,
      hasConsent: gateway.hasConsent,
      coreActionComplete: _coreActionDone,
      // Asked here rather than trusted from the call site: a caller that
      // *looks* foreground can still be reached from a timer that kept
      // running after the user left, and AdMob blocks serving for an app
      // that shows full-screen ads from the background.
      appForegrounded: WidgetsBinding.instance.lifecycleState ==
          AppLifecycleState.resumed,
    );
    if (refusal != null) return;

    if (await gateway.showInterstitial()) {
      _session = _session.recordInterstitial(now);
    }
  }

  void dispose() => gateway.dispose();
}
