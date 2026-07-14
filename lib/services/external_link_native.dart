import 'package:flutter/services.dart';

const _channel = MethodChannel('supercajon.app/external_link');

Future<bool> openExternalLink(String url) async {
  try {
    return await _channel.invokeMethod<bool>('openUrl', {'url': url}) ?? false;
  } on PlatformException {
    return false;
  } on MissingPluginException {
    return false;
  }
}
