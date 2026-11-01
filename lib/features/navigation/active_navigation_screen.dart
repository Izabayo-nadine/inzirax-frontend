import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzirax/features/navigation/driver_map.dart';
import 'package:inzirax/features/navigation/incident_reporting_sheet.dart';
import 'package:inzirax/features/navigation/navigation_controller.dart';
import 'package:inzirax/models/live_alert.dart';

const _bg = Color(0xff0d0f14);
const _surface = Color(0xff161b22);
const _border = Color(0xff30363d);
const _primary = Color(0xff6c63ff);
const _secondary = Color(0xff00d4aa);
const _textDim = Color(0xff8b949e);

class ActiveNavigationScreen extends ConsumerWidget {
  const ActiveNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navigationProvider);
    final alert = state.alerts.firstOrNull;
    final speed = state.position?.speedKph.round() ?? 0;
    final limit = alert?.speedLimit;

    return PopScope(
      onPopInvokedWithResult: (_, __) =>
          ref.read(navigationProvider.notifier).stopNavigation(),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            // full map
            Positioned.fill(
              child: DriverMap(
                position: state.position,
                route: state.selectedRoute,
                followDriver: true,
              ),
            ),

            // top overlay
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // maneuver banner
                    _ManeuverBanner(
                      destination:
                          state.destination?.name ?? 'Following route',
                    ),
                    if (alert != null) ...[
                      const SizedBox(height: 10),
                      _AlertBanner(alert: alert),
                    ],
                  ],
                ),
              ),
            ),

            // speed HUD — bottom left
            Positioned(
              left: 16,
              bottom: 90,
              child: _SpeedHud(speed: speed, speedLimit: limit),
            ),

            // report button — bottom right
            Positioned(
              right: 16,
              bottom: 90,
              child: _ReportButton(
                onTap: () => IncidentReportingSheet.show(
                  context,
                  ref.read(navigationProvider.notifier).reportIncident,
                ),
              ),
            ),

            // end navigation — bottom center
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    await ref
                        .read(navigationProvider.notifier)
                        .stopNavigation();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xffff6b6b).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: const Color(0xffff6b6b).withOpacity(0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stop_circle_outlined,
                            color: Color(0xffff6b6b), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'End Navigation',
                          style: TextStyle(
                            color: Color(0xffff6b6b),
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Maneuver banner ──────────────────────────────────────────
class _ManeuverBanner extends StatelessWidget {
  const _ManeuverBanner({required this.destination});
  final String destination;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface.withOpacity(0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _primary.withOpacity(0.4)),
              ),
              child:
                  const Icon(Icons.straight_rounded, color: _primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Continue straight',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _textDim, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Alert banner ─────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert});
  final LiveAlert alert;

  @override
  Widget build(BuildContext context) {
    final isCamera = alert.kind == AlertKind.camera;
    final color =
        isCamera ? const Color(0xffff9f43) : const Color(0xffff6b6b);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isCamera
                ? Icons.camera_alt_rounded
                : Icons.warning_amber_rounded,
            color: color,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${alert.distanceMeters.round()} m · ${alert.detail}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Speed HUD ────────────────────────────────────────────────
class _SpeedHud extends StatelessWidget {
  const _SpeedHud({required this.speed, this.speedLimit});
  final int speed;
  final int? speedLimit;

  @override
  Widget build(BuildContext context) {
    final overLimit =
        speedLimit != null && speed > speedLimit!;
    return Row(
      children: [
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: _surface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$speed',
                style: TextStyle(
                  color: overLimit
                      ? const Color(0xffff6b6b)
                      : Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 38,
                  height: 1,
                ),
              ),
              const Text(
                'km/h',
                style: TextStyle(color: _textDim, fontSize: 11),
              ),
            ],
          ),
        ),
        if (speedLimit != null) ...[
          const SizedBox(width: 8),
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                  color: const Color(0xffff6b6b), width: 5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              '$speedLimit',
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Report button ─────────────────────────────────────────────
class _ReportButton extends StatelessWidget {
  const _ReportButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: _surface.withOpacity(0.92),
            shape: BoxShape.circle,
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3), blurRadius: 8),
            ],
          ),
          child: const Icon(Icons.report_problem_outlined,
              color: Color(0xffff9f43), size: 22),
        ),
      );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
