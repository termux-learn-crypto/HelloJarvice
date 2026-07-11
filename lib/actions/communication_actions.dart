import 'package:url_launcher/url_launcher.dart';

class CommunicationActions {
  static Future<String> makeCall(String name) async {
    Uri tel = Uri.parse('tel:$name');
    if (await canLaunchUrl(tel)) {
      await launchUrl(tel);
      return '$name ko call kar raha hoon';
    }
    return 'Call nahi ho paya';
  }

  static Future<String> sendWhatsApp(String name, [String? message]) async {
    String msg = message ?? 'Hello';
    String url = 'https://wa.me/$name?text=${Uri.encodeComponent(msg)}';
    Uri wa = Uri.parse(url);
    if (await canLaunchUrl(wa)) {
      await launchUrl(wa);
      return '$name ko WhatsApp bhej raha hoon';
    }
    return 'WhatsApp nahi ho paya';
  }
}
