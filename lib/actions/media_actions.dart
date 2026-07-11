import '../actions/web_actions.dart';

class MediaActions {
  static Future<String> playMusic(String? query) async {
    if (query == null || query.isEmpty) {
      return 'Kya gaana chalaun?';
    }
    return await WebActions.openYouTube(query);
  }

  static Future<String> playVideo(String? query) async {
    if (query == null || query.isEmpty) {
      return 'Kya video chalaun?';
    }
    return await WebActions.openYouTube(query);
  }
}
