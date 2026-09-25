import 'package:shared_preferences/shared_preferences.dart';
import 'package:vitals_ads/vitals_ads.dart';

/// The app's side of [AdPolicy]: it holds the counters the rules read, keeps
/// them across launches, and is the only thing the UI talks to.
///
/// **Banners only.** The interstitial was removed at the user's request: it
/// still exists in `vitals_ads` for other apps, but nothing here loads or shows
/// one, so no full-screen ad can appear.
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
  }

  /// Records that the user has reached the point of the app at least once.
  ///
  /// In LockIn that is finishing a focus block: before that has happened the
  /// ledger has never paid out, and the app has not yet shown what it is for.
  Future<void> markCoreAction() async {
    if (_coreActionDone) return;
    _coreActionDone = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_coreActionKey, true);
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

  void dispose() => gateway.dispose();
}
