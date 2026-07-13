import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/permission_service.dart';

class PermissionsScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const PermissionsScreen({super.key, required this.onComplete});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  Map<String, bool> _permissions = {};
  bool _loading = true;
  bool _navigated = false;

  static const _steps = [
    _StepInfo('microphone', 'Microphone', 'Aapki baat sunne ke liye', Icons.mic, true),
    _StepInfo('notification', 'Notifications', 'Background service ke liye', Icons.notifications, true),
    _StepInfo('location', 'Location', 'Mausam aur location ke liye (optional)', Icons.location_on, false),
    _StepInfo('accessibility', 'Accessibility', 'Screen pe kaam karne ke liye', Icons.accessibility_new, false),
    _StepInfo('notificationListener', 'Notification Listener', 'Notifications padhne ke liye', Icons.mark_email_read, false),
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _loading = true);
    _permissions = await PermissionService.checkAllPermissions();
    _permissions['accessibility'] = false;
    _permissions['notificationListener'] = false;
    setState(() => _loading = false);

    if (_permissions['microphone'] == true &&
        _permissions['notification'] == true &&
        !_navigated) {
      _navigated = true;
      widget.onComplete();
    }
  }

  Future<void> _requestPermission(String permission) async {
    bool granted = false;
    switch (permission) {
      case 'microphone':
        granted = await PermissionService.requestMicrophonePermission();
        break;
      case 'notification':
        granted = await PermissionService.requestNotificationPermission();
        break;
      case 'location':
        granted = await PermissionService.requestLocationPermission();
        break;
      case 'accessibility':
      case 'notificationListener':
        _showServiceGuide(permission);
        return;
    }

    if (!granted) {
      PermissionStatus status;
      switch (permission) {
        case 'microphone':
          status = await Permission.microphone.status;
          break;
        case 'notification':
          status = await Permission.notification.status;
          break;
        case 'location':
          status = await Permission.location.status;
          break;
        default:
          status = PermissionStatus.denied;
      }

      if (status.isPermanentlyDenied && mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text('Settings mein jaakar permission enable karein.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      }
    }

    _permissions[permission] = granted;
    setState(() {});

    if (_permissions['microphone'] == true &&
        _permissions['notification'] == true &&
        !_navigated) {
      _navigated = true;
      widget.onComplete();
    }
  }

  void _showServiceGuide(String service) {
    final isAccessibility = service == 'accessibility';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(
          isAccessibility ? Icons.accessibility_new : Icons.mark_email_read,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(isAccessibility ? 'Accessibility Service' : 'Notification Listener'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAccessibility
                  ? 'Screen pe click, scroll, aur text type karne ke liye Accessibility service zaroori hai.'
                  : 'Notifications padhne aur dismiss karne ke liye Notification Listener service zaroori hai.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text('Steps:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(isAccessibility
                ? '1. Settings > Accessibility\n2. "Hello Jarvice" dhundhein\n3. Enable karein\n4. Wapas aayein'
                : '1. Settings > Notification access\n2. "Hello Jarvice" dhundhein\n3. Enable karein\n4. Wapas aayein'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final requiredGranted = _permissions['microphone'] == true && _permissions['notification'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        actions: [
          if (requiredGranted)
            TextButton(
              onPressed: () {
                if (!_navigated) {
                  _navigated = true;
                  widget.onComplete();
                }
              },
              child: const Text('Skip'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.mic, size: 64, color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Hello Jarvice Setup',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ye permissionsJarvice ko kaam karne ke liye chahiye.\nRequired permissions pehle enable karein.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _steps.length,
                itemBuilder: (ctx, i) {
                  final step = _steps[i];
                  final granted = _permissions[step.key] ?? false;
                  final isRequired = step.required;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(step.icon, color: granted ? Colors.green : Colors.grey),
                      title: Row(
                        children: [
                          Text(step.title),
                          if (isRequired)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Text('*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      subtitle: Text(step.subtitle, style: const TextStyle(fontSize: 12)),
                      trailing: granted
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : ElevatedButton(
                              onPressed: () => _requestPermission(step.key),
                              child: Text(step.key == 'accessibility' || step.key == 'notificationListener' ? 'Enable' : 'Grant'),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: requiredGranted
                    ? () {
                        if (!_navigated) {
                          _navigated = true;
                          widget.onComplete();
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  requiredGranted ? 'Shuru karein' : 'Pehle required permissions dein',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepInfo {
  final String key;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool required;

  const _StepInfo(this.key, this.title, this.subtitle, this.icon, this.required);
}
