import 'capability.dart';
import 'capability_result.dart';
import 'capability_registry.dart';
import 'conversation_context.dart';
import '../models/action_plan.dart';
import '../services/command_router.dart';

class CapabilityExecutor {
  static final CapabilityExecutor instance = CapabilityExecutor._();
  CapabilityExecutor._();

  NativeResult? _lastNativeResult;

  NativeResult? get lastNativeResult => _lastNativeResult;

  Future<CapabilityResult> executePlan(ActionPlan plan) async {
    final context = ConversationContext.instance;

    for (var i = 0; i < plan.steps.length; i++) {
      final step = plan.steps[i];
      if (step.status == PlanStepStatus.completed || step.status == PlanStepStatus.skipped) continue;

      plan = plan.updateStep(i, step.copyWith(status: PlanStepStatus.inProgress));

      if (step.parameters.containsKey('_missingRequired')) {
        final missing = step.parameters['_missingRequired'] as List<String>;
        plan = plan.updateStep(i, step.copyWith(
          status: PlanStepStatus.failed,
          failedReason: 'Missing required parameters: $missing',
        ));
        continue;
      }

      if (step.parameters.containsKey('_dependsOnContactLookup')) {
        final contactName = step.parameters['contactName'] as String?;
        if (contactName != null) {
          final contactResult = await CommandRouter.lookupContact(contactName);
          if (contactResult.success && contactResult.data.containsKey('number')) {
            final number = contactResult.data['number'].toString();
            context.updateContact(contactName, phoneNumber: number);
            final updatedParams = Map<String, dynamic>.from(step.parameters)
              ..remove('_dependsOnContactLookup')
              ..['phoneNumber'] = number;
            plan = plan.updateStep(i, step.copyWith(parameters: updatedParams));
          } else {
            plan = plan.updateStep(i, step.copyWith(
              status: PlanStepStatus.failed,
              failedReason: 'Contact not found: $contactName',
            ));
            continue;
          }
        }
      }

      final result = await _executeStep(step);
      _lastNativeResult = null;

      if (result.isSuccess) {
        plan = plan.updateStep(i, step.copyWith(status: PlanStepStatus.completed));
        _updateContext(step, result);
      } else if (result.status == CapabilityStatus.needsConfirmation) {
        return result;
      } else if (result.status == CapabilityStatus.permissionRequired ||
          result.status == CapabilityStatus.accessibilityRequired ||
          result.status == CapabilityStatus.notificationListenerRequired) {
        plan = plan.updateStep(i, step.copyWith(status: PlanStepStatus.failed, failedReason: result.message));
        return result;
      } else {
        plan = plan.updateStep(i, step.copyWith(status: PlanStepStatus.failed, failedReason: result.message));
        if (plan.steps.where((s) => s.isFailed).length >= 2) {
          return result;
        }
      }
    }

    final failedCount = plan.steps.where((s) => s.isFailed).length;
    final completedCount = plan.steps.where((s) => s.isCompleted).length;

    if (failedCount == 0 && completedCount > 0) {
      return CapabilityResult.success(
        'All $completedCount task(s) completed successfully.',
        data: {'completedTasks': completedCount, 'totalTasks': plan.steps.length},
      );
    } else if (completedCount > 0) {
      return CapabilityResult(
        status: CapabilityStatus.partiallyCompleted,
        message: '$completedCount of ${plan.steps.length} tasks completed',
        spokenResponse: 'Kuch kaam ho gaye, kuch nahi.',
      );
    } else {
      return CapabilityResult.failed('No tasks could be completed');
    }
  }

  Future<CapabilityResult> executeSingle(String capabilityId, Map<String, dynamic> parameters) async {
    final registry = CapabilityRegistry.instance;
    final capability = registry.getCapability(capabilityId);
    if (capability == null) {
      return CapabilityResult.notFound(capabilityId);
    }

    final step = PlanStep(
      capabilityId: capabilityId,
      category: capability.category,
      operation: capability.operation,
      parameters: parameters,
    );

    final result = await _executeStep(step);
    if (result.isSuccess) {
      _updateContext(step, result);
    }
    return result;
  }

  Future<CapabilityResult> _executeStep(PlanStep step) async {
    switch (step.category) {
      case CapabilityCategory.application:
        return _executeApp(step);
      case CapabilityCategory.contact:
        return _executeContact(step);
      case CapabilityCategory.call:
        return _executeCall(step);
      case CapabilityCategory.whatsapp:
        return _executeWhatsApp(step);
      case CapabilityCategory.message:
        return _executeMessage(step);
      case CapabilityCategory.volume:
        return _executeVolume(step);
      case CapabilityCategory.brightness:
        return _executeBrightness(step);
      case CapabilityCategory.torch:
        return _executeTorch(step);
      case CapabilityCategory.media:
        return _executeMedia(step);
      case CapabilityCategory.youtube:
        return _executeYouTube(step);
      case CapabilityCategory.alarm:
        return _executeAlarm(step);
      case CapabilityCategory.timer:
        return _executeTimer(step);
      case CapabilityCategory.reminder:
        return _executeReminder(step);
      case CapabilityCategory.datetime:
        return _executeDateTime(step);
      case CapabilityCategory.web:
        return _executeWeb(step);
      case CapabilityCategory.wifi:
        return _executeWifi(step);
      case CapabilityCategory.bluetooth:
        return _executeBluetooth(step);
      case CapabilityCategory.network:
        return _executeNetwork(step);
      case CapabilityCategory.location:
        return _executeLocation(step);
      case CapabilityCategory.accessibility:
        return _executeAccessibility(step);
      case CapabilityCategory.screenInteraction:
        return _executeScreenInteraction(step);
      case CapabilityCategory.notification:
        return _executeNotification(step);
      case CapabilityCategory.device:
        return _executeDevice(step);
      case CapabilityCategory.settings:
        return _executeSettings(step);
      case CapabilityCategory.screenControl:
        return _executeScreenControl(step);
      case CapabilityCategory.rotation:
        return _executeRotation(step);
      case CapabilityCategory.dnd:
        return _executeDnd(step);
      case CapabilityCategory.clipboard:
        return _executeClipboard(step);
      case CapabilityCategory.camera:
        return _executeCamera(step);
      case CapabilityCategory.file:
        return _executeFile(step);
      case CapabilityCategory.weather:
        return _executeWeather(step);
    }
  }

  CapabilityResult _wrap(NativeResult r, String id) {
    _lastNativeResult = r;
    return CapabilityResult.fromNativeResult({'success': r.success, 'message': r.message, 'data': r.data, 'errorCode': r.errorCode}, capabilityId: id);
  }

  Future<CapabilityResult> _executeApp(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'OPEN_APPLICATION':
        final name = step.parameters['appName'] as String? ?? '';
        final pkg = step.parameters['packageName'] as String?;
        final r = await CommandRouter.launchApp(pkg ?? name);
        return _wrap(r, id);
      case 'CLOSE_APPLICATION':
        final appName = step.parameters['appName'] as String? ?? '';
        final pkg = step.parameters['packageName'] as String? ?? appName;
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'closeApp', {'package': pkg});
        return _wrap(r, id);
      case 'FIND_INSTALLED_APPLICATION':
        final name = step.parameters['appName'] as String? ?? '';
        final r = await CommandRouter.searchApps(name);
        return _wrap(r, id);
      case 'LIST_INSTALLED_APPLICATIONS':
        final r = await CommandRouter.searchApps('');
        return _wrap(r, id);
      case 'GET_FOREGROUND_APPLICATION':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getForegroundApp');
        return _wrap(r, id);
      case 'OPEN_APPLICATION_INFO':
        final name = step.parameters['appName'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openAppInfo', {'package': name});
        return _wrap(r, id);
      case 'OPEN_APPLICATION_SETTINGS':
        final name = step.parameters['appName'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openAppSettings', {'package': name});
        return _wrap(r, id);
      case 'OPEN_APPLICATION_NOTIFICATION_SETTINGS':
        final name = step.parameters['appName'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openAppNotificationSettings', {'package': name});
        return _wrap(r, id);
      case 'OPEN_APPLICATION_PERMISSION_SETTINGS':
        final name = step.parameters['appName'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openAppPermissionSettings', {'package': name});
        return _wrap(r, id);
      case 'OPEN_DEFAULT_APPLICATION_SETTINGS':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openDefaultAppSettings');
        return _wrap(r, id);
      case 'OPEN_URL':
        final url = step.parameters['url'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openUrl', {'url': url});
        return _wrap(r, id);
      case 'OPEN_DEEP_LINK':
        final uri = step.parameters['uri'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openDeepLink', {'uri': uri});
        return _wrap(r, id);
      case 'OPEN_FILE_WITH_APPLICATION':
        final path = step.parameters['filePath'] as String? ?? '';
        final appName = step.parameters['appName'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openFileWith', {'path': path, 'app': appName});
        return _wrap(r, id);
      case 'SHARE_TEXT':
        final text = step.parameters['text'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'shareText', {'text': text});
        return _wrap(r, id);
      case 'SHARE_FILE':
        final path = step.parameters['filePath'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'shareFile', {'path': path});
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeContact(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'FIND_CONTACT':
      case 'SEARCH_CONTACTS':
      case 'RESOLVE_CONTACT':
        final query = step.parameters['contactName'] as String? ?? step.parameters['query'] as String? ?? '';
        final r = await CommandRouter.lookupContact(query);
        return _wrap(r, id);
      case 'GET_CONTACT_PHONE_NUMBERS':
        final name = step.parameters['contactName'] as String? ?? '';
        final r = await CommandRouter.lookupContact(name);
        return _wrap(r, id);
      case 'OPEN_CONTACT':
        final name = step.parameters['contactName'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openContact', {'name': name});
        return _wrap(r, id);
      case 'CREATE_CONTACT':
        final name = step.parameters['contactName'] as String? ?? '';
        final phone = step.parameters['phoneNumber'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'createContact', {'name': name, 'phone': phone});
        return _wrap(r, id);
      case 'EDIT_CONTACT':
        final name = step.parameters['contactName'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'editContact', {'name': name});
        return _wrap(r, id);
      case 'OPEN_CONTACT_PICKER':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openContactPicker');
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeCall(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'DIAL_NUMBER':
        final number = step.parameters['phoneNumber'] as String? ?? '';
        final r = await CommandRouter.dialNumber(number);
        return _wrap(r, id);
      case 'CALL_NUMBER':
        final number = step.parameters['phoneNumber'] as String? ?? '';
        final r = await CommandRouter.makeCall(number);
        return _wrap(r, id);
      case 'CALL_CONTACT':
        final name = step.parameters['contactName'] as String? ?? '';
        if (name.isNotEmpty) {
          final r = await CommandRouter.makeCall(name);
          return _wrap(r, id);
        }
        final number = step.parameters['phoneNumber'] as String? ?? '';
        final r = await CommandRouter.makeCall(number);
        return _wrap(r, id);
      case 'REDIAL_LAST_SUPPORTED_CALL':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'redialLast');
        return _wrap(r, id);
      case 'OPEN_DIALER':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openDialer');
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeWhatsApp(PlanStep step) async {
    final id = step.capabilityId;
    final contact = step.parameters['contactName'] as String? ?? '';
    final message = step.parameters['message'] as String? ?? '';

    switch (id) {
      case 'OPEN_WHATSAPP':
        final r = await CommandRouter.launchApp('com.whatsapp');
        return _wrap(r, id);
      case 'OPEN_WHATSAPP_CONTACT':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openWhatsAppChat', {'contact': contact});
        return _wrap(r, id);
      case 'OPEN_WHATSAPP_CHAT':
        final number = step.parameters['phoneNumber'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openWhatsAppChatById', {'phone': number});
        return _wrap(r, id);
      case 'PREPARE_WHATSAPP_MESSAGE':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'prepareWhatsAppMessage', {'contact': contact, 'message': message});
        return _wrap(r, id);
      case 'SEND_WHATSAPP_MESSAGE':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'prepareWhatsAppMessage', {'contact': contact, 'message': message});
        return _wrap(r, id);
      case 'START_WHATSAPP_AUDIO_CALL':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'whatsappAudioCall', {'contact': contact});
        return _wrap(r, id);
      case 'START_WHATSAPP_VIDEO_CALL':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'whatsappVideoCall', {'contact': contact});
        return _wrap(r, id);
      case 'OPEN_WHATSAPP_CAMERA':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openWhatsAppCamera');
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeMessage(PlanStep step) async {
    final id = step.capabilityId;
    final contact = step.parameters['contactName'] as String? ?? '';
    final message = step.parameters['message'] as String? ?? '';

    switch (id) {
      case 'PREPARE_SMS':
      case 'PREPARE_MESSAGE':
        if (contact.isEmpty || message.isEmpty) {
          return CapabilityResult.failed('Need contact and message', capabilityId: id);
        }
        final r = await CommandRouter.composeSms(contact, message);
        return _wrap(r, id);
      case 'SEND_SMS':
        return CapabilityResult.needsConfirmation('Send SMS to $contact', capabilityId: id);
      case 'OPEN_SMS_COMPOSER':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openSmsComposer', {'recipient': contact});
        return _wrap(r, id);
      case 'CONFIRM_MESSAGE':
        if (contact.isNotEmpty && message.isNotEmpty) {
          final r = await CommandRouter.composeSms(contact, message);
          return _wrap(r, id);
        }
        return CapabilityResult.failed('No pending message to confirm', capabilityId: id);
      case 'SHARE_MESSAGE':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'shareText', {'text': message});
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeVolume(PlanStep step) async {
    final id = step.capabilityId;
    final stream = step.parameters['streamType'] as String? ?? 'music';
    final pct = step.parameters['percentage'] as int?;

    switch (id) {
      case 'GET_VOLUME':
        final r = await CommandRouter.getVolumeInfo(stream: stream);
        return _wrap(r, id);
      case 'SET_VOLUME':
        if (pct == null) return CapabilityResult.failed('Percentage required', capabilityId: id);
        final r = await CommandRouter.setVolume(pct, stream: stream);
        return _wrap(r, id);
      case 'INCREASE_VOLUME':
        final r = await CommandRouter.volumeUp(stream: stream);
        return _wrap(r, id);
      case 'DECREASE_VOLUME':
        final r = await CommandRouter.volumeDown(stream: stream);
        return _wrap(r, id);
      case 'MUTE_VOLUME':
        final r = await CommandRouter.muteVolume(stream: stream);
        return _wrap(r, id);
      case 'UNMUTE_VOLUME':
        final r = await CommandRouter.unmuteVolume(stream: stream);
        return _wrap(r, id);
      case 'MAXIMIZE_VOLUME':
        final r = await CommandRouter.maxVolume(stream: stream);
        return _wrap(r, id);
      case 'MINIMIZE_VOLUME':
        final r = await CommandRouter.setVolume(5, stream: stream);
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeBrightness(PlanStep step) async {
    final id = step.capabilityId;
    final pct = step.parameters['percentage'] as int?;

    switch (id) {
      case 'GET_BRIGHTNESS':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getBrightness');
        return _wrap(r, id);
      case 'SET_BRIGHTNESS':
        if (pct == null) return CapabilityResult.failed('Percentage required', capabilityId: id);
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'setBrightness', {'percent': pct});
        return _wrap(r, id);
      case 'INCREASE_BRIGHTNESS':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'increaseBrightness');
        return _wrap(r, id);
      case 'DECREASE_BRIGHTNESS':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'decreaseBrightness');
        return _wrap(r, id);
      case 'MAXIMIZE_BRIGHTNESS':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'setBrightness', {'percent': 100});
        return _wrap(r, id);
      case 'MINIMIZE_BRIGHTNESS':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'setBrightness', {'percent': 0});
        return _wrap(r, id);
      case 'ENABLE_AUTO_BRIGHTNESS':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'setAutoBrightness', {'enabled': true});
        return _wrap(r, id);
      case 'DISABLE_AUTO_BRIGHTNESS':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'setAutoBrightness', {'enabled': false});
        return _wrap(r, id);
      case 'OPEN_BRIGHTNESS_SETTINGS':
        return _executeSettings(step);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeTorch(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'GET_TORCH_STATE':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getTorchState');
        return _wrap(r, id);
      case 'TURN_TORCH_ON':
        final r = await CommandRouter.torchOn();
        return _wrap(r, id);
      case 'TURN_TORCH_OFF':
        final r = await CommandRouter.torchOff();
        return _wrap(r, id);
      case 'TOGGLE_TORCH':
        final r = await CommandRouter.torchToggle();
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeMedia(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'MEDIA_PLAY':
      case 'MEDIA_RESUME':
        final r = await CommandRouter.mediaPlay();
        return _wrap(r, id);
      case 'MEDIA_PAUSE':
        final r = await CommandRouter.mediaPause();
        return _wrap(r, id);
      case 'MEDIA_STOP':
        final r = await CommandRouter.mediaStop();
        return _wrap(r, id);
      case 'MEDIA_NEXT':
        final r = await CommandRouter.mediaNext();
        return _wrap(r, id);
      case 'MEDIA_PREVIOUS':
        final r = await CommandRouter.mediaPrevious();
        return _wrap(r, id);
      case 'GET_MEDIA_STATE':
      case 'GET_CURRENT_MEDIA':
        final r = await CommandRouter.getPlaybackState();
        return _wrap(r, id);
      case 'OPEN_MEDIA_APPLICATION':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getMediaApp');
        return _wrap(r, id);
      case 'SEARCH_MEDIA':
      case 'PLAY_MEDIA_QUERY':
        final query = step.parameters['query'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'playMediaQuery', {'query': query});
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeYouTube(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'OPEN_YOUTUBE':
        final r = await CommandRouter.openYouTube();
        return _wrap(r, id);
      case 'SEARCH_YOUTUBE':
      case 'PLAY_YOUTUBE_QUERY':
        final query = step.parameters['query'] as String? ?? '';
        final r = await CommandRouter.openYouTubeSearch(query);
        return _wrap(r, id);
      case 'OPEN_YOUTUBE_URL':
        final url = step.parameters['url'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openUrl', {'url': url});
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeAlarm(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'SET_ALARM':
        final hour = step.parameters['hour'] as int?;
        final minute = step.parameters['minute'] as int? ?? 0;
        if (hour == null) return CapabilityResult.failed('Hour required', capabilityId: id);
        final label = step.parameters['label'] as String? ?? 'Jarvice Alarm';
        final r = await CommandRouter.setAlarm(hour, minute, label: label);
        return _wrap(r, id);
      case 'SHOW_ALARMS':
        final r = await CommandRouter.showAlarms();
        return _wrap(r, id);
      case 'OPEN_CLOCK_APPLICATION':
        final r = await CommandRouter.launchApp('com.google.android.deskclock');
        return _wrap(r, id);
      case 'DISMISS_SUPPORTED_ALARM':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'dismissAlarm');
        return _wrap(r, id);
      case 'SNOOZE_SUPPORTED_ALARM':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'snoozeAlarm');
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeTimer(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'SET_TIMER':
        final duration = step.parameters['duration'] as int?;
        if (duration == null) return CapabilityResult.failed('Duration required', capabilityId: id);
        final minutes = (duration / 60).ceil();
        final r = await CommandRouter.setTimer(minutes);
        return _wrap(r, id);
      case 'SHOW_TIMERS':
      case 'OPEN_TIMER':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'openTimer');
        return _wrap(r, id);
      case 'DISMISS_SUPPORTED_TIMER':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'dismissTimer');
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeReminder(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'CREATE_REMINDER':
        final title = step.parameters['title'] as String? ?? step.parameters['text'] as String? ?? 'Reminder';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'createReminder', {'title': title, ...step.parameters});
        return _wrap(r, id);
      case 'LIST_REMINDERS':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'listReminders');
        return _wrap(r, id);
      case 'UPDATE_REMINDER':
      case 'DELETE_REMINDER':
      case 'COMPLETE_REMINDER':
      case 'SNOOZE_REMINDER':
        final reminderId = step.parameters['reminderId'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, step.capabilityId.toLowerCase(), {'id': reminderId});
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeDateTime(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'GET_CURRENT_TIME':
        final r = await CommandRouter.getCurrentTime();
        return _wrap(r, id);
      case 'GET_CURRENT_DATE':
        final now = DateTime.now();
        final months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return CapabilityResult.success(
          '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]} ${now.year}',
          spokenResponse: 'Aaj ${days[now.weekday - 1]} hai, ${now.day} ${months[now.month - 1]} ${now.year}',
          capabilityId: id,
        );
      case 'GET_DAY':
        final now = DateTime.now();
        final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        return CapabilityResult.success(
          days[now.weekday - 1],
          spokenResponse: 'Aaj ${days[now.weekday - 1]} hai.',
          capabilityId: id,
        );
      case 'PARSE_RELATIVE_TIME':
      case 'PARSE_NATURAL_DATE_TIME':
        final text = step.parameters['text'] as String? ?? '';
        return CapabilityResult.success(text, spokenResponse: 'Time parse ho gaya.', capabilityId: id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeWeb(PlanStep step) async {
    final id = step.capabilityId;
    final query = step.parameters['query'] as String? ?? '';

    switch (id) {
      case 'WEB_SEARCH':
      case 'OPEN_SEARCH_RESULT':
      case 'SEARCH_QUERY':
        if (query.isEmpty) return CapabilityResult.failed('Query required', capabilityId: id);
        final r = await CommandRouter.searchGoogle(query);
        return _wrap(r, id);
      case 'OPEN_BROWSER':
        final r = await CommandRouter.launchApp('chrome');
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeWifi(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'GET_WIFI_STATE':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getWifiState');
        return _wrap(r, id);
      case 'ENABLE_WIFI_IF_SUPPORTED':
        final r = await CommandRouter.toggleWiFi(true);
        return _wrap(r, id);
      case 'DISABLE_WIFI_IF_SUPPORTED':
        final r = await CommandRouter.toggleWiFi(false);
        return _wrap(r, id);
      case 'OPEN_WIFI_PANEL':
        final r = await CommandRouter.openSettings('wifi');
        return _wrap(r, id);
      case 'OPEN_WIFI_SETTINGS':
        final r = await CommandRouter.openSettings('wifi');
        return _wrap(r, id);
      case 'GET_CONNECTED_WIFI_INFORMATION':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getConnectedWifi');
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeBluetooth(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'GET_BLUETOOTH_STATE':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getBluetoothState');
        return _wrap(r, id);
      case 'ENABLE_BLUETOOTH_IF_SUPPORTED':
        final r = await CommandRouter.toggleBluetooth(true);
        return _wrap(r, id);
      case 'DISABLE_BLUETOOTH_IF_SUPPORTED':
        final r = await CommandRouter.toggleBluetooth(false);
        return _wrap(r, id);
      case 'OPEN_BLUETOOTH_SETTINGS':
        final r = await CommandRouter.openSettings('bluetooth');
        return _wrap(r, id);
      case 'OPEN_BLUETOOTH_PANEL':
        final r = await CommandRouter.openSettings('bluetooth');
        return _wrap(r, id);
      case 'GET_BONDED_DEVICES':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getBondedDevices');
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeNetwork(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'OPEN_MOBILE_NETWORK_SETTINGS':
        final r = await CommandRouter.openSettings('network');
        return _wrap(r, id);
      case 'OPEN_DATA_USAGE_SETTINGS':
        final r = await CommandRouter.openSettings('data_usage');
        return _wrap(r, id);
      case 'GET_NETWORK_STATE':
      case 'GET_CONNECTION_TYPE':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getNetworkState');
        return _wrap(r, id);
      case 'OPEN_AIRPLANE_MODE_SETTINGS':
        final r = await CommandRouter.openSettings('airplane');
        return _wrap(r, id);
      case 'SET_MOBILE_DATA_PRIVILEGED':
      case 'SET_AIRPLANE_MODE_PRIVILEGED':
        final r = await CommandRouter.getShizukuStatus();
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeLocation(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'GET_CURRENT_LOCATION':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getCurrentLocation');
        return _wrap(r, id);
      case 'CHECK_LOCATION_STATE':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getLocationState');
        return _wrap(r, id);
      case 'OPEN_LOCATION_SETTINGS':
        final r = await CommandRouter.openSettings('location');
        return _wrap(r, id);
      case 'OPEN_MAP':
        final r = await CommandRouter.launchApp('com.google.android.apps.maps');
        return _wrap(r, id);
      case 'NAVIGATE_TO_LOCATION':
        final dest = step.parameters['destination'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'navigateTo', {'destination': dest});
        return _wrap(r, id);
      case 'SEARCH_PLACE':
        final query = step.parameters['query'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'searchPlace', {'query': query});
        return _wrap(r, id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeAccessibility(PlanStep step) async {
    final id = step.capabilityId;
    final a11y = await CommandRouter.isAccessibilityEnabled();
    if (a11y.data['enabled'] != true) {
      return CapabilityResult.accessibilityRequired(capabilityId: id);
    }

    switch (id) {
      case 'GO_BACK': return _wrap(await CommandRouter.performBack(), id);
      case 'GO_HOME': return _wrap(await CommandRouter.performHome(), id);
      case 'OPEN_RECENTS': return _wrap(await CommandRouter.performRecents(), id);
      case 'OPEN_NOTIFICATIONS': return _wrap(await CommandRouter.performNotifications(), id);
      case 'OPEN_QUICK_SETTINGS': return _wrap(await CommandRouter.performQuickSettings(), id);
      case 'SCROLL_UP': return _wrap(await CommandRouter.performScrollUp(), id);
      case 'SCROLL_DOWN': return _wrap(await CommandRouter.performScrollDown(), id);
      case 'SCROLL_LEFT':
        return _wrap(await CommandRouter.performSwipe(800, 1200, 200, 1200), id);
      case 'SCROLL_RIGHT':
        return _wrap(await CommandRouter.performSwipe(200, 1200, 800, 1200), id);
      case 'SWIPE_GESTURE':
        final sx = (step.parameters['startX'] as num?)?.toDouble() ?? 0;
        final sy = (step.parameters['startY'] as num?)?.toDouble() ?? 0;
        final ex = (step.parameters['endX'] as num?)?.toDouble() ?? 0;
        final ey = (step.parameters['endY'] as num?)?.toDouble() ?? 0;
        return _wrap(await CommandRouter.performSwipe(sx, sy, ex, ey), id);
      case 'CLICK_VISIBLE_TEXT':
      case 'CLICK_VISIBLE_ELEMENT':
      case 'LONG_CLICK_VISIBLE_ELEMENT':
      case 'FOCUS_VISIBLE_ELEMENT':
        final r = await CommandRouter.getWindowHierarchy();
        return _wrap(r, id);
      case 'SET_VISIBLE_TEXT':
        final text = step.parameters['text'] as String? ?? '';
        return _wrap(await CommandRouter.call(CommandRouter.accessibilityChannel, 'setText', {'text': text}), id);
      case 'CLEAR_VISIBLE_TEXT':
        return _wrap(await CommandRouter.call(CommandRouter.accessibilityChannel, 'clearText'), id);
      case 'FIND_VISIBLE_TEXT':
        final text = step.parameters['text'] as String? ?? '';
        final r = await CommandRouter.getWindowHierarchy();
        if (r.success && r.data.containsKey('hierarchy')) {
          final hierarchy = r.data['hierarchy'].toString();
          final found = hierarchy.toLowerCase().contains(text.toLowerCase());
          return CapabilityResult(
            status: found ? CapabilityStatus.success : CapabilityStatus.notFound,
            message: found ? 'Text "$text" found on screen' : 'Text "$text" not found on screen',
            spokenResponse: found ? 'Haan, screen pe "$text" dikhai de raha hai.' : 'Nahi, screen pe "$text" nahi hai.',
            data: {'found': found, 'text': text},
            executedCapabilityId: id,
          );
        }
        return _wrap(r, id);
      case 'GET_CURRENT_WINDOW_TITLE':
        return _wrap(await CommandRouter.getWindowHierarchy(), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeScreenInteraction(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'TAP_COORDINATE':
        final x = (step.parameters['x'] as num?)?.toDouble() ?? 0;
        final y = (step.parameters['y'] as num?)?.toDouble() ?? 0;
        return _wrap(await CommandRouter.performClick(x, y), id);
      case 'LONG_PRESS_COORDINATE':
        final x = (step.parameters['x'] as num?)?.toDouble() ?? 0;
        final y = (step.parameters['y'] as num?)?.toDouble() ?? 0;
        return _wrap(await CommandRouter.performSwipe(x, y, x, y), id);
      case 'SWIPE_COORDINATES':
        final sx = (step.parameters['startX'] as num?)?.toDouble() ?? 0;
        final sy = (step.parameters['startY'] as num?)?.toDouble() ?? 0;
        final ex = (step.parameters['endX'] as num?)?.toDouble() ?? 0;
        final ey = (step.parameters['endY'] as num?)?.toDouble() ?? 0;
        return _wrap(await CommandRouter.performSwipe(sx, sy, ex, ey), id);
      case 'TYPE_TEXT_IN_FOCUSED_FIELD':
        final text = step.parameters['text'] as String? ?? '';
        return _wrap(await CommandRouter.call(CommandRouter.accessibilityChannel, 'typeText', {'text': text}), id);
      case 'PRESS_ENTER':
        return _wrap(await CommandRouter.call(CommandRouter.accessibilityChannel, 'pressEnter'), id);
      case 'PRESS_BACK':
        return _wrap(await CommandRouter.performBack(), id);
      case 'PRESS_HOME':
        return _wrap(await CommandRouter.performHome(), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeNotification(PlanStep step) async {
    final id = step.capabilityId;
    final hasListener = await CommandRouter.isNotificationListenerEnabled();
    if (hasListener.data['enabled'] != true) {
      return CapabilityResult.notificationListenerRequired(capabilityId: id);
    }

    switch (id) {
      case 'LIST_NOTIFICATIONS':
      case 'READ_NOTIFICATIONS':
        return _wrap(await CommandRouter.getRecentNotifications(), id);
      case 'READ_APPLICATION_NOTIFICATIONS':
        final appName = step.parameters['appName'] as String? ?? '';
        return _wrap(await CommandRouter.getNotificationsByApp(appName), id);
      case 'FIND_NOTIFICATION':
        final query = step.parameters['query'] as String? ?? '';
        final r = await CommandRouter.getRecentNotifications();
        if (r.success && r.data.containsKey('notifications')) {
          final notifications = r.data['notifications'] as List? ?? [];
          final matches = notifications.where((n) =>
            n.toString().toLowerCase().contains(query.toLowerCase())
          ).toList();
          return CapabilityResult(
            status: matches.isNotEmpty ? CapabilityStatus.success : CapabilityStatus.notFound,
            message: '${matches.length} notification(s) found',
            data: {'notifications': matches},
            executedCapabilityId: id,
          );
        }
        return _wrap(r, id);
      case 'OPEN_NOTIFICATION':
        final key = step.parameters['notificationKey'] as String? ?? '';
        return _wrap(await CommandRouter.call(CommandRouter.notificationChannel, 'openNotification', {'key': key}), id);
      case 'DISMISS_NOTIFICATION':
        final key = step.parameters['notificationKey'] as String? ?? '';
        return _wrap(await CommandRouter.dismissNotification(key), id);
      case 'DISMISS_APPLICATION_NOTIFICATIONS':
        final appName = step.parameters['appName'] as String? ?? '';
        return _wrap(await CommandRouter.call(CommandRouter.notificationChannel, 'dismissAppNotifications', {'package': appName}), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeDevice(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'GET_BATTERY_LEVEL':
        return _wrap(await CommandRouter.getBatteryLevel(), id);
      case 'GET_CHARGING_STATE':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'getChargingState'), id);
      case 'GET_DEVICE_MODEL':
      case 'GET_ANDROID_VERSION':
        return _wrap(await CommandRouter.getDeviceInfo(), id);
      case 'GET_STORAGE_INFORMATION':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'getStorageInfo'), id);
      case 'GET_MEMORY_INFORMATION':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'getMemoryInfo'), id);
      case 'GET_NETWORK_INFORMATION':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'getNetworkInfo'), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeSettings(PlanStep step) async {
    final id = step.capabilityId;
    final section = step.parameters['section'] as String? ?? '';
    switch (id) {
      case 'OPEN_SETTINGS':
        return _wrap(await CommandRouter.openSettings(section.isNotEmpty ? section : 'main'), id);
      case 'OPEN_DISPLAY_SETTINGS': return _wrap(await CommandRouter.openSettings('display'), id);
      case 'OPEN_SOUND_SETTINGS': return _wrap(await CommandRouter.openSettings('sound'), id);
      case 'OPEN_APPLICATION_SETTINGS': return _wrap(await CommandRouter.openSettings('apps'), id);
      case 'OPEN_ACCESSIBILITY_SETTINGS': return _wrap(await CommandRouter.openSettings('accessibility'), id);
      case 'OPEN_NOTIFICATION_SETTINGS': return _wrap(await CommandRouter.openSettings('notification'), id);
      case 'OPEN_BATTERY_SETTINGS': return _wrap(await CommandRouter.openBatterySettings(), id);
      case 'OPEN_LOCATION_SETTINGS': return _wrap(await CommandRouter.openSettings('location'), id);
      case 'OPEN_SECURITY_SETTINGS': return _wrap(await CommandRouter.openSettings('security'), id);
      case 'OPEN_DATE_TIME_SETTINGS': return _wrap(await CommandRouter.openSettings('datetime'), id);
      case 'OPEN_LANGUAGE_SETTINGS': return _wrap(await CommandRouter.openSettings('language'), id);
      default: return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeScreenControl(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'WAKE_SCREEN':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'wakeScreen'), id);
      case 'KEEP_SCREEN_AWAKE':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'keepScreenAwake', {'enabled': true}), id);
      case 'RELEASE_KEEP_SCREEN_AWAKE':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'keepScreenAwake', {'enabled': false}), id);
      case 'GET_SCREEN_STATE':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'getScreenState'), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeRotation(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'GET_ROTATION_STATE':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'getRotationState'), id);
      case 'ENABLE_AUTO_ROTATE':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'setAutoRotate', {'enabled': true}), id);
      case 'DISABLE_AUTO_ROTATE':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'setAutoRotate', {'enabled': false}), id);
      case 'SET_PORTRAIT_IF_SUPPORTED':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'setOrientation', {'orientation': 'portrait'}), id);
      case 'SET_LANDSCAPE_IF_SUPPORTED':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'setOrientation', {'orientation': 'landscape'}), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeDnd(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'GET_DND_STATE':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'getDndState'), id);
      case 'ENABLE_DND':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'setDnd', {'enabled': true}), id);
      case 'DISABLE_DND':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'setDnd', {'enabled': false}), id);
      case 'OPEN_DND_ACCESS_SETTINGS':
        return _wrap(await CommandRouter.openSettings('dnd_access'), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeClipboard(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'COPY_TEXT':
        final text = step.parameters['text'] as String? ?? '';
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'copyToClipboard', {'text': text});
        return _wrap(r, id);
      case 'GET_CLIPBOARD_TEXT':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getClipboardText');
        if (r.success && r.data.containsKey('text')) {
          return CapabilityResult.success(
            r.data['text'].toString(),
            spokenResponse: 'Clipboard mein "${r.data['text']}" hai.',
            data: r.data,
            capabilityId: id,
          );
        }
        return _wrap(r, id);
      case 'CLEAR_CLIPBOARD':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'clearClipboard'), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeCamera(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'OPEN_CAMERA':
        return _wrap(await CommandRouter.launchApp('camera'), id);
      case 'OPEN_FRONT_CAMERA_IF_SUPPORTED':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'openCamera', {'facing': 'front'}), id);
      case 'OPEN_REAR_CAMERA_IF_SUPPORTED':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'openCamera', {'facing': 'rear'}), id);
      case 'OPEN_VIDEO_CAMERA':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'openCamera', {'mode': 'video'}), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeFile(PlanStep step) async {
    final id = step.capabilityId;
    switch (id) {
      case 'OPEN_FILE':
        final path = step.parameters['filePath'] as String? ?? '';
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'openFile', {'path': path}), id);
      case 'SHARE_FILE_CAPABILITY':
        final path = step.parameters['filePath'] as String? ?? '';
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'shareFile', {'path': path}), id);
      case 'OPEN_DOWNLOADS':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'openDownloads'), id);
      case 'OPEN_DOCUMENT_PICKER':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'openDocumentPicker'), id);
      case 'SEARCH_USER_SELECTED_FILES':
        final query = step.parameters['query'] as String? ?? '';
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'searchFiles', {'query': query}), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  Future<CapabilityResult> _executeWeather(PlanStep step) async {
    final id = step.capabilityId;
    final city = step.parameters['city'] as String?;
    switch (id) {
      case 'GET_WEATHER':
      case 'GET_CURRENT_LOCATION_WEATHER':
      case 'GET_TEMPERATURE':
        final r = await CommandRouter.call(CommandRouter.systemChannel, 'getWeather', city != null ? {'city': city} : null);
        return _wrap(r, id);
      case 'GET_CITY_WEATHER':
        if (city == null) return CapabilityResult.failed('City name required', capabilityId: id);
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'getWeather', {'city': city}), id);
      case 'GET_WEATHER_FORECAST':
        return _wrap(await CommandRouter.call(CommandRouter.systemChannel, 'getWeatherForecast', city != null ? {'city': city} : null), id);
      default:
        return CapabilityResult.notFound(id);
    }
  }

  void _updateContext(PlanStep step, CapabilityResult result) {
    final context = ConversationContext.instance;
    final params = step.parameters;

    context.updateAction(step.capabilityId, step.capabilityId);

    if (params.containsKey('contactName')) {
      context.updateContact(
        params['contactName'] as String,
        phoneNumber: params['phoneNumber'] as String?,
      );
    }
    if (params.containsKey('appName')) {
      context.updateApp(
        params['appName'] as String,
        packageName: params['packageName'] as String?,
      );
    }
    if (params.containsKey('message')) {
      context.updateMessage(params['message'] as String);
    }
  }
}
