import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inzirax/features/settings/settings_controller.dart';

const _bg = Color(0xff0d0f14);
const _surface = Color(0xff161b22);
const _surfaceVar = Color(0xff1e2530);
const _border = Color(0xff30363d);
const _primary = Color(0xff6c63ff);
const _secondary = Color(0xff00d4aa);
const _textDim = Color(0xff8b949e);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  static const routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final permission = settings.locationPermission;
    final granted = permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: const Text(
          'Settings',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Section: Alerts ──────────────────────────────────
          _SectionLabel('Alerts'),
          const SizedBox(height: 10),
          _Card(
            child: Column(
              children: [
                _Row(
                  icon: Icons.record_voice_over_outlined,
                  iconColor: _secondary,
                  title: 'Voice alerts',
                  subtitle: 'Announce cameras & incidents aloud',
                  trailing: Switch.adaptive(
                    value: settings.voiceAlerts,
                    activeColor: _primary,
                    onChanged:
                        ref.read(settingsProvider.notifier).setVoiceAlerts,
                  ),
                ),
                const _Divider(),
                _Row(
                  icon: Icons.radar_rounded,
                  iconColor: _primary,
                  title: 'Warning distance',
                  subtitle: '${settings.warningDistanceMeters.round()} m ahead',
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _primary,
                      inactiveTrackColor: _surfaceVar,
                      thumbColor: _primary,
                      overlayColor: _primary.withOpacity(0.12),
                      valueIndicatorColor: _primary,
                    ),
                    child: Slider(
                      min: 300,
                      max: 1000,
                      divisions: 7,
                      label: '${settings.warningDistanceMeters.round()} m',
                      value: settings.warningDistanceMeters,
                      onChanged: ref
                          .read(settingsProvider.notifier)
                          .setWarningDistance,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section: Permissions ──────────────────────────────
          _SectionLabel('Permissions'),
          const SizedBox(height: 10),
          _Card(
            child: _Row(
              icon: granted ? Icons.location_on_rounded : Icons.location_off_rounded,
              iconColor: granted ? _secondary : const Color(0xffff9f43),
              title: 'Background location',
              subtitle: _permissionLabel(permission),
              trailing: granted
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _secondary.withOpacity(0.4)),
                      ),
                      child: const Text('Granted',
                          style: TextStyle(
                              color: _secondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    )
                  : TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: _primary.withOpacity(0.12),
                        foregroundColor: _primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                      ),
                      onPressed: () async {
                        await Geolocator.requestPermission();
                        await ref
                            .read(settingsProvider.notifier)
                            .refreshPermission();
                      },
                      child: const Text('Allow',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
            ),
          ),

          const SizedBox(height: 32),

          // ── Version footer ────────────────────────────────────
          const Center(
            child: Text(
              'Inzirax v1.0.0',
              style: TextStyle(color: _textDim, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _permissionLabel(LocationPermission permission) =>
      switch (permission) {
        LocationPermission.always => 'Allowed always',
        LocationPermission.whileInUse => 'Allowed while using the app',
        LocationPermission.deniedForever => 'Blocked in system settings',
        _ => 'Not allowed – tap Allow',
      };
}

// ── helpers ───────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: _textDim,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: child,
      );
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: _textDim, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
      );
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        thickness: 1,
        color: _border,
        indent: 16,
        endIndent: 16,
      );
}
