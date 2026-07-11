import '../services/intent_parser.dart';
import '../actions/system_actions.dart';
import '../actions/communication_actions.dart';
import '../actions/web_actions.dart';
import '../actions/utility_actions.dart';
import '../actions/media_actions.dart';

class ActionHandler {
  static Future<String> execute(IntentResult intent) async {
    try {
      switch (intent.action) {
        case 'CALL':
          String name = intent.params['value1'] ?? '';
          return await CommunicationActions.makeCall(name);

        case 'WHATSAPP':
          String name = intent.params['value1'] ?? '';
          String msg = intent.params['value2'] ?? '';
          return await CommunicationActions.sendWhatsApp(name, msg);

        case 'WIFI_ON':
          return await SystemActions.toggleWiFi('on');

        case 'WIFI_OFF':
          return await SystemActions.toggleWiFi('off');

        case 'BLUETOOTH_ON':
          return await SystemActions.toggleBluetooth('on');

        case 'BLUETOOTH_OFF':
          return await SystemActions.toggleBluetooth('off');

        case 'FLASHLIGHT_ON':
          return await SystemActions.toggleFlashlight('on');

        case 'FLASHLIGHT_OFF':
          return await SystemActions.toggleFlashlight('off');

        case 'WEATHER':
          String city = intent.params['value1'] ?? intent.params['value2'] ?? '';
          return await WebActions.getWeather(city.isNotEmpty ? city : null);

        case 'TIME':
          return await WebActions.getTime();

        case 'ALARM':
          String time = intent.params['value1'] ?? intent.params['value3'] ?? '';
          return await UtilityActions.setAlarm(time);

        case 'SEARCH':
          String query = intent.params['value1'] ?? intent.params['value2'] ?? '';
          return await WebActions.searchWeb(query);

        case 'NOTE':
          String content = intent.params['value1'] ?? intent.params['value2'] ?? '';
          return await UtilityActions.createNote(content);

        case 'OPEN':
          String appName = intent.params['value1'] ?? intent.params['value2'] ?? '';
          return await UtilityActions.launchApp(appName);

        default:
          return 'Mujhe samajh nahi aaya. Phir se boliye.';
      }
    } catch (e) {
      return 'Kuch gadbad hui. Phir se koshish karein.';
    }
  }
}
