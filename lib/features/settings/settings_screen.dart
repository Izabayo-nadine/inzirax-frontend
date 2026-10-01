import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inzirax/features/settings/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final permission = settings.locationPermission;
    final granted = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SwitchListTile.adaptive(
          title: const Text('Voice alerts'),
          subtitle: const Text('Announce nearby cameras and traffic incidents'),
          value: settings.voiceAlerts,
          onChanged: ref.read(settingsProvider.notifier).setVoiceAlerts,
        ),
        const Divider(),
        ListTile(
          title: const Text('Camera warning distance'),
          subtitle: Text('${settings.warningDistanceMeters.round()} m'),
        ),
        Slider(
          min: 300,
          max: 1000,
          divisions: 7,
          label: '${settings.warningDistanceMeters.round()} m',
          value: settings.warningDistanceMeters,
          onChanged: ref.read(settingsProvider.notifier).setWarningDistance,
        ),
        const Divider(),
        ListTile(
          leading: Icon(granted ? Icons.location_on : Icons.location_off, color: granted ? Colors.green : Colors.orange),
          title: const Text('Background location permission'),
          subtitle: Text(_permissionLabel(permission)),
          trailing: granted ? const Icon(Icons.check_circle, color: Colors.green) : TextButton(
            onPressed: () async {
              await Geolocator.requestPermission();
              await ref.read(settingsProvider.notifier).refreshPermission();
            },
            child: const Text('Allow'),
          ),
        ),
      ]),
    );
  }

  String _permissionLabel(LocationPermission permission) => switch (permission) {
        LocationPermission.always => 'Allowed always',
        LocationPermission.whileInUse => 'Allowed while using the app',
        LocationPermission.deniedForever => 'Blocked in system settings',
        _ => 'Not allowed',
      };
}
