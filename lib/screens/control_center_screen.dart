import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tts_service.dart';
import '../services/command_router.dart';
import '../services/diagnostics_service.dart';

class ControlCenterScreen extends StatefulWidget {
  final TtsService ttsService;

  const ControlCenterScreen({super.key, required this.ttsService});

  @override
  State<ControlCenterScreen> createState() => _ControlCenterScreenState();
}

class _ControlCenterScreenState extends State<ControlCenterScreen> {
  double _speechRate = 0.4;
  double _pitch = 1.0;
  bool _accessibilityEnabled = false;
  bool _notificationListenerEnabled = false;
  String _shizukuStatus = 'unknown';
  bool _rootAvailable = false;
  Map<String, dynamic> _diagnostics = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _speechRate = widget.ttsService.speechRate;
    _pitch = widget.ttsService.pitch;
    _loadStatuses();
  }

  Future<void> _loadStatuses() async {
    setState(() => _loading = true);

    try {
      final accResult = await CommandRouter.isAccessibilityEnabled();
      _accessibilityEnabled = accResult.data['enabled'] ?? false;
    } catch (_) {}

    try {
      final notifResult = await CommandRouter.isNotificationListenerEnabled();
      _notificationListenerEnabled = notifResult.data['enabled'] ?? false;
    } catch (_) {}

    try {
      final shizukuResult = await CommandRouter.getShizukuStatus();
      _shizukuStatus = shizukuResult.data['status']?.toString() ?? 'unknown';
    } catch (_) {}

    try {
      final rootResult = await CommandRouter.getRootStatus();
      _rootAvailable = rootResult.data['available'] ?? false;
    } catch (_) {}

    try {
      _diagnostics = await DiagnosticsService().getDiagnostics();
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jarvice Control Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatuses,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildVoiceSection(),
                const SizedBox(height: 12),
                _buildAndroidControlSection(),
                const SizedBox(height: 12),
                _buildPermissionsSection(),
                const SizedBox(height: 12),
                _buildAdvancedSection(),
                const SizedBox(height: 12),
                _buildSystemSection(),
                const SizedBox(height: 12),
                _buildDiagnosticsSection(),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Widget _buildVoiceSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('VOICE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Speech Speed'),
              subtitle: Slider(
                value: _speechRate,
                min: 0.1,
                max: 1.0,
                divisions: 9,
                label: _speechRate.toStringAsFixed(1),
                onChanged: (val) {
                  setState(() => _speechRate = val);
                  widget.ttsService.updateSettings(speechRate: val);
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: const Text('Speech Pitch'),
              subtitle: Slider(
                value: _pitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                label: _pitch.toStringAsFixed(1),
                onChanged: (val) {
                  setState(() => _pitch = val);
                  widget.ttsService.updateSettings(pitch: val);
                },
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAndroidControlSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ANDROID CONTROL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            _statusTile(
              icon: Icons.assistant,
              title: 'Default Assistant',
              subtitle: 'Set Jarvice as default assistant',
              status: null,
              onTap: () => _requestAssistantRole(),
            ),
            _statusTile(
              icon: Icons.accessibility_new,
              title: 'Accessibility Control',
              subtitle: _accessibilityEnabled ? 'Enabled' : 'Disabled',
              status: _accessibilityEnabled,
              onTap: () => _openAccessibilitySettings(),
            ),
            _statusTile(
              icon: Icons.notifications_active,
              title: 'Notification Access',
              subtitle: _notificationListenerEnabled ? 'Enabled' : 'Disabled',
              status: _notificationListenerEnabled,
              onTap: () => _openNotificationSettings(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PERMISSIONS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            _statusTile(
              icon: Icons.mic,
              title: 'Microphone',
              subtitle: 'Voice input',
              status: true,
              onTap: null,
            ),
            _statusTile(
              icon: Icons.contacts,
              title: 'Contacts',
              subtitle: 'Contact lookup for calls/SMS',
              status: null,
              onTap: () => CommandRouter.openSettings('app'),
            ),
            _statusTile(
              icon: Icons.phone,
              title: 'Phone',
              subtitle: 'Direct calling',
              status: null,
              onTap: () => CommandRouter.openSettings('app'),
            ),
            _statusTile(
              icon: Icons.chat,
              title: 'SMS',
              subtitle: 'Sending messages',
              status: null,
              onTap: () => CommandRouter.openSettings('app'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    String shizukuLabel;
    switch (_shizukuStatus) {
      case 'connected':
        shizukuLabel = 'Connected';
        break;
      case 'not_installed':
        shizukuLabel = 'Not Installed';
        break;
      case 'not_running':
        shizukuLabel = 'Not Running';
        break;
      case 'permission_required':
        shizukuLabel = 'Permission Required';
        break;
      default:
        shizukuLabel = 'Unknown';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ADVANCED CONTROL', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            _statusTile(
              icon: Icons.extension,
              title: 'Shizuku',
              subtitle: shizukuLabel,
              status: _shizukuStatus == 'connected',
              onTap: null,
            ),
            _statusTile(
              icon: Icons.terminal,
              title: 'Root Control',
              subtitle: _rootAvailable ? 'Available' : 'Not Available',
              status: _rootAvailable,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SYSTEM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.battery_std),
              title: const Text('Battery Optimization'),
              subtitle: const Text('Ensure Jarvice runs in background'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => CommandRouter.openBatterySettings(),
              contentPadding: EdgeInsets.zero,
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('App Version'),
              subtitle: const Text('1.0.0'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('DIAGNOSTICS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo)),
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy'),
                  onPressed: () {
                    final text = DiagnosticsService().formatDiagnostics(_diagnostics);
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Diagnostics copied!')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_diagnostics.isNotEmpty) ...[
              _diagRow('Manufacturer', _diagnostics['manufacturer']?.toString() ?? 'Unknown'),
              _diagRow('Model', _diagnostics['model']?.toString() ?? 'Unknown'),
              _diagRow('Android', _diagnostics['androidVersion']?.toString() ?? 'Unknown'),
              _diagRow('Battery', '${_diagnostics['batteryLevel'] ?? -1}%'),
              _diagRow('Charging', '${_diagnostics['isCharging'] ?? false}'),
              _diagRow('Accessibility', '${_diagnostics['accessibilityEnabled'] ?? false}'),
              _diagRow('Notification Listener', '${_diagnostics['notificationListenerEnabled'] ?? false}'),
              _diagRow('Shizuku', '${_diagnostics['shizukuStatus'] ?? 'unknown'}'),
              _diagRow('Root', '${_diagnostics['rootAvailable'] ?? false}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool? status,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: status == true ? Colors.green : status == false ? Colors.grey : Colors.indigo),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: status != null
          ? Icon(
              status ? Icons.check_circle : Icons.cancel,
              color: status ? Colors.green : Colors.grey,
            )
          : (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _diagRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  void _requestAssistantRole() async {
    try {
      await CommandRouter.openSettings('accessibility');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings mein jaakar Default Assistant set karein'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {}
  }

  void _openAccessibilitySettings() async {
    try {
      await CommandRouter.openSettings('accessibility');
    } catch (_) {}
  }

  void _openNotificationSettings() async {
    try {
      await CommandRouter.openSettings('notification');
    } catch (_) {}
  }
}
