import 'package:flutter/services.dart';

/// Opens web pages in the phone's browser.
///
/// A single intent on the Kotlin side rather than a `url_launcher`
/// dependency: the app opens exactly one kind of link, and a plugin for one
/// intent is more to keep updated than it saves.
final class AndroidLinks {
  const AndroidLinks({this.channel = const MethodChannel('tally/usage')});

  final MethodChannel channel;

  /// The privacy policy. Both stores require it reachable from inside the
  /// app, and it must describe the ad SDK the app ships.
  static const privacyPolicyUrl = 'https://rastovic.github.io/lockin/privacy/';

  /// Opens [url]. False when nothing could open it, so the caller can say so
  /// rather than leave a tap that did nothing.
  Future<bool> open(String url) async {
    try {
      return await channel.invokeMethod<bool>('openUrl', {'url': url}) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
