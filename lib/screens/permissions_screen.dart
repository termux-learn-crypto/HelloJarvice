import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _loading = true);
    _permissions = await PermissionService.checkAllPermissions();
    setState(() => _loading = false);
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
    }
    _permissions[permission] = granted;
    setState(() {});

    if (_permissions['microphone'] == true &&
        _permissions['notification'] == true) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Permissions Required')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic, size: 80, color: Theme.of(context).primaryColor),
            SizedBox(height: 24),
            Text(
              'Jarvis ko permissions chahiye',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'App ko background mein sunne ke liye permissions zaroori hain',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 32),
            _permissionTile('microphone', 'Microphone', 'Aapki baat sunne ke liye', Icons.mic),
            SizedBox(height: 12),
            _permissionTile('notification', 'Notification', 'Background service ke liye', Icons.notifications),
            SizedBox(height: 12),
            _permissionTile('location', 'Location', 'Mausam ke liye (optional)', Icons.location_on),
          ],
        ),
      ),
    );
  }

  Widget _permissionTile(String key, String title, String subtitle, IconData icon) {
    bool granted = _permissions[key] ?? false;
    return Card(
      child: ListTile(
        leading: Icon(icon, color: granted ? Colors.green : Colors.grey),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: granted
            ? Icon(Icons.check_circle, color: Colors.green)
            : ElevatedButton(
                onPressed: () => _requestPermission(key),
                child: Text('Grant'),
              ),
      ),
    );
  }
}
