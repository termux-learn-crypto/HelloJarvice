import 'capability_result.dart';

class ResponseGenerator {
  static final ResponseGenerator instance = ResponseGenerator._();
  ResponseGenerator._();

  static final _successResponses = <String, List<String>>{
    'OPEN_APPLICATION': ['%s khol diya.', '%s shuru kar diya.', 'Ye lo, %s open hai.'],
    'CLOSE_APPLICATION': ['%s band kar diya.', '%s ko close kar diya.', '%s khattam ho gaya.'],
    'SET_ALARM': ['Alarm set ho gaya %s baje.', '%s ka alarm laga diya.', 'Theek hai, %s baje alarm bajega.'],
    'SET_TIMER': ['Timer set ho gaya %s ke liye.', '%s minute ka timer shuru.', 'Timer lag gaya %s minutes.'],
    'DIAL_NUMBER': ['%s ko dial kar raha hoon.', 'Call laga raha hoon %s pe.'],
    'CALL_CONTACT': ['%s ko call lag raha hai.', '%s se call connect ho raha hai.'],
    'PREPARE_SMS': ['%s ke liye SMS ready hai.', 'Message likh diya %s ke liye.'],
    'WEB_SEARCH': ['%s ke liye search kar raha hoon.', '%s dhoondh raha hoon Google pe.'],
    'GET_CURRENT_TIME': ['Abhi %s baj rahe hain.', 'Time hai %s.'],
    'GET_CURRENT_DATE': ['Aaj %s hai.', 'Date hai %s.'],
    'TURN_TORCH_ON': ['Torch on kar diya.', 'Flashlight jala diya.'],
    'TURN_TORCH_OFF': ['Torch band kar diya.', 'Flashlight off kar diya.'],
    'TOGGLE_TORCH': ['Torch toggle kar diya.', 'Flashlight ki state change kar di.'],
    'INCREASE_VOLUME': ['Volume badha diya.', 'Awaaz zyada kar di.'],
    'DECREASE_VOLUME': ['Volume ghata diya.', 'Awaaz kam kar di.'],
    'MUTE_VOLUME': ['Volume mute kar diya.', 'Awaaz band kar di.'],
    'UNMUTE_VOLUME': ['Volume unmute kar diya.', 'Awaaz wapas on kar di.'],
    'SET_VOLUME': ['Volume %s%% set kar diya.', 'Awaaz %s%% kar di.'],
    'ENABLE_WIFI': ['WiFi on kar diya.', 'WiFi shuru kar diya.'],
    'DISABLE_WIFI': ['WiFi band kar diya.', 'WiFi off kar diya.'],
    'ENABLE_BLUETOOTH': ['Bluetooth on kar diya.', 'Bluetooth shuru kar diya.'],
    'DISABLE_BLUETOOTH': ['Bluetooth band kar diya.', 'Bluetooth off kar diya.'],
    'GO_BACK': ['Back kar diya.', 'Peeche chala gaya.'],
    'GO_HOME': ['Home screen pe ja raha hoon.', 'Home pe chalte hain.'],
    'OPEN_RECENTS': ['Recent apps khol diye.', 'Recents dikhata hoon.'],
    'OPEN_NOTIFICATIONS': ['Notifications khol raha hoon.', 'Notification shade open kar diya.'],
    'MEDIA_PLAY': ['Music bajana shuru kar diya.', 'Play kar diya.'],
    'MEDIA_PAUSE': ['Music rok diya.', 'Pause kar diya.'],
    'MEDIA_NEXT': ['Agla gaana laga raha hoon.', 'Next track.'],
    'MEDIA_PREVIOUS': ['Pichla gaana laga raha hoon.', 'Previous track.'],
    'GET_BATTERY_LEVEL': ['Battery %s%% hai.', 'Battery level %s%% hai.'],
    'OPEN_SETTINGS': ['Settings khol diye.', 'Settings open kar diye.'],
    'OPEN_WHATSAPP': ['WhatsApp khol diya.', 'WhatsApp open ho raha hai.'],
    'OPEN_WHATSAPP_CONTACT': ['%s ka WhatsApp khol raha hoon.', 'WhatsApp pe %s se baat karte hain.'],
    'OPEN_WHATSAPP_CHAT': ['WhatsApp chat khula: %s.', '%s se WhatsApp pe baat karo.'],
    'PREPARE_WHATSAPP_MESSAGE': ['%s ke liye WhatsApp message ready hai.'],
    'SEND_WHATSAPP_MESSAGE': ['%s ko WhatsApp message bhej diya.', 'Message bhej diya %s ko.'],
    'START_WHATSAPP_AUDIO_CALL': ['%s ko WhatsApp call laga raha hoon.', 'WhatsApp pe %s se call ho raha hai.'],
    'START_WHATSAPP_VIDEO_CALL': ['%s ko WhatsApp video call kar raha hoon.', 'Video call laga raha hoon %s pe.'],
    'OPEN_WHATSAPP_CAMERA': ['WhatsApp camera khol diya.', 'Camera ready hai WhatsApp ke liye.'],
    'COPY_TEXT': ['Text copy ho gaya.', 'Clipboard mein save ho gaya.'],
    'GET_CLIPBOARD_TEXT': ['Clipboard mein "%s" hai.'],
    'CREATE_REMINDER': ['Reminder set ho gaya.', 'Yaad dila doonga.'],
    'NAVIGATE_TO_LOCATION': ['%s pe navigate kar raha hoon.', 'Map pe %s dikha raha hoon.'],
  };

  static final _errorResponses = <String, List<String>>{
    'PERMISSION_REQUIRED': ['Iske liye permission chahiye. %s allow karo.', 'Permission denied hai. Settings mein jaake enable karo.'],
    'ACCESSIBILITY_REQUIRED': ['Iske liye Accessibility service chahiye. Settings mein jaake enable karo.'],
    'NOTIFICATION_LISTENER_REQUIRED': ['Notifications padhne ke liye service chahiye. Settings mein enable karo.'],
    'NOT_FOUND': ['Sorry, %s nahi mila.', '%s dhoondh nahi paya.'],
    'APP_NOT_FOUND': ['%s install nahi hai phone mein.', 'Ye app nahi mili.'],
    'CONTACT_NOT_FOUND': ['%s naam ka contact nahi mila.', 'Contact nahi mila.'],
    'FAILED': ['Kaam nahi ho paya.', 'Sorry, ye kar nahi paya.', 'Kuch gadbad ho gayi.'],
    'USER_DENIED': ['Theek hai, skip karte hain.', 'Koi baat nahi.'],
    'ALREADY_IN_STATE': ['Ye pehle se wahi hai.', 'Already set hai.'],
  };

  String generateResponse(CapabilityResult result, {String? capabilityId}) {
    if (result.spokenResponse.isNotEmpty && result.spokenResponse != result.message) {
      return result.spokenResponse;
    }

    final id = capabilityId ?? result.executedCapabilityId ?? '';

    if (result.isSuccess) {
      final templates = _successResponses[id];
      if (templates != null && templates.isNotEmpty) {
        final template = templates[DateTime.now().millisecond % templates.length];
        final data = result.data;
        if (data.containsKey('value')) {
          return template.replaceAll('%s', data['value'].toString());
        }
        if (data.containsKey('hour') && data.containsKey('minute')) {
          return template.replaceAll('%s', '${data['hour']}:${(data['minute'] as int).toString().padLeft(2, '0')}');
        }
        if (data.containsKey('percentage')) {
          return template.replaceAll('%s', '${data['percentage']}');
        }
        return template;
      }
      return result.message.isNotEmpty ? result.message : 'Ho gaya.';
    }

    final errorCode = result.errorCode ?? _statusToErrorCode(result.status);
    final templates = _errorResponses[errorCode];
    if (templates != null && templates.isNotEmpty) {
      final template = templates[DateTime.now().millisecond % templates.length];
      return template.replaceAll('%s', result.message);
    }

    return result.message.isNotEmpty ? result.message : 'Sorry, kaam nahi ho paya.';
  }

  String _statusToErrorCode(CapabilityStatus status) {
    switch (status) {
      case CapabilityStatus.permissionRequired:
        return 'PERMISSION_REQUIRED';
      case CapabilityStatus.accessibilityRequired:
        return 'ACCESSIBILITY_REQUIRED';
      case CapabilityStatus.notificationListenerRequired:
        return 'NOTIFICATION_LISTENER_REQUIRED';
      case CapabilityStatus.notFound:
        return 'NOT_FOUND';
      case CapabilityStatus.userDenied:
        return 'USER_DENIED';
      case CapabilityStatus.alreadyInState:
        return 'ALREADY_IN_STATE';
      default:
        return 'FAILED';
    }
  }

  String generateClarification(String missingParam) {
    final responses = {
      'contactName': ['Kiska naam batao?', 'Kaun hai ye?', 'Naam toh batao.'],
      'phoneNumber': ['Number kya hai?', 'Phone number batao.'],
      'appName': ['Kaun sa app?', 'App ka naam batao.'],
      'query': ['Kya dhoondhna hai?', 'Search mein kya dalun?'],
      'city': ['Kaun sa sheher?', 'City ka naam batao.'],
      'message': ['Kya likhna hai message?', 'Message kya hai?'],
      'text': ['Kya text hai?', 'Kya likhna hai?'],
      'destination': ['Kahan jaana hai?', 'Destination batao.'],
      'duration': ['Kitna time?', 'Kitni der ke liye?'],
      'percentage': ['Kitna percent?', 'Kitna set karna hai?'],
      'time': ['Kab? Time batao.', 'Kitne baje?'],
    };

    final templates = responses[missingParam] ?? ['Thoda aur detail batao.'];
    return templates[DateTime.now().millisecond % templates.length];
  }

  String generateMultiStepAcknowledgment(List<String> stepDescriptions) {
    if (stepDescriptions.length == 1) {
      return 'Samajh gaya. ${stepDescriptions[0]}';
    }
    final buffer = StringBuffer('Samajh gaya. ${stepDescriptions.length} kaam karne hain: ');
    for (var i = 0; i < stepDescriptions.length; i++) {
      buffer.write('${i + 1}. ${stepDescriptions[i]}');
      if (i < stepDescriptions.length - 1) buffer.write(', ');
    }
    return buffer.toString();
  }
}
