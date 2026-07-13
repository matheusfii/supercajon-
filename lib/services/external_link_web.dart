import 'package:web/web.dart';

Future<bool> openExternalLink(String url) async {
  window.open(url, '_blank');
  return true;
}
