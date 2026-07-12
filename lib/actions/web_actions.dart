import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class WebActions {
  static Future<String> getWeather([String? city]) async {
    String loc = city ?? 'Delhi';
    try {
      final response = await http.get(
        Uri.parse('https://wttr.in/$loc?format=%C+%t'),
      );
      if (response.statusCode == 200) {
        String weather = response.body.trim();
        return '$loc ka mausam: $weather';
      }
      return 'Mausam nahi mil paya';
    } catch (e) {
      return 'Mausam ke liye internet chahiye';
    }
  }

  static Future<String> searchWeb(String query) async {
    Uri searchUrl = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(searchUrl)) {
      await launchUrl(searchUrl);
      return '$query search kar raha hoon';
    }
    return 'Search nahi ho paya';
  }

  static Future<String> getTime() async {
    var now = DateTime.now();
    String h = now.hour.toString().padLeft(2, '0');
    String m = now.minute.toString().padLeft(2, '0');
    return 'Time: $h:$m';
  }

  static Future<String> openYouTube(String query) async {
    Uri url = Uri.parse('https://www.youtube.com/results?search_query=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
      return 'YouTube pe $query search kiya';
    }
    return 'YouTube nahi khula';
  }
}
