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

    String? number = await _resolveContactNumber(name);
    if (number != null) {
      number = number.replaceAll(RegExp(r'[^0-9+]'), '');
      String url = 'https://wa.me/$number?text=${Uri.encodeComponent(msg)}';
      Uri wa = Uri.parse(url);
      if (await canLaunchUrl(wa)) {
        await launchUrl(wa);
        return '$name ko WhatsApp bhej raha hoon';
      }
    }

    try {
      String url = 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
      Uri wa = Uri.parse(url);
      if (await canLaunchUrl(wa)) {
        await launchUrl(wa);
        return 'WhatsApp khula - contact select karein';
      }
    } catch (_) {}

    return 'WhatsApp nahi ho paya';
  }

  static Future<String?> _resolveContactNumber(String name) async {
    if (RegExp(r'^\+?\d{7,15}$').hasMatch(name)) {
      return name;
    }
    return null;
  }
}
