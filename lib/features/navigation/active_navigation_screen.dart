import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inzirax/features/navigation/driver_map.dart';
import 'package:inzirax/features/navigation/incident_reporting_sheet.dart';
import 'package:inzirax/features/navigation/navigation_controller.dart';
import 'package:inzirax/models/live_alert.dart';

class ActiveNavigationScreen extends ConsumerWidget {
  const ActiveNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navigationProvider);
    final alert = state.alerts.firstOrNull;
    final speed = state.position?.speedKph.round() ?? 0;
    final limit = alert?.speedLimit;
    return PopScope(
      onPopInvokedWithResult: (_, __) => ref.read(navigationProvider.notifier).stopNavigation(),
      child: Scaffold(
        body: Stack(children: [
          Positioned.fill(child: DriverMap(position: state.position, route: state.selectedRoute, followDriver: true)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _ManeuverBanner(routeName: state.destination?.name ?? 'Following route'),
                if (alert != null) Padding(padding: const EdgeInsets.only(top: 12), child: _AlertBanner(alert: alert)),
                const Spacer(),
                _SpeedHud(speed: speed, speedLimit: limit),
              ]),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 155,
            child: FloatingActionButton.extended(
              heroTag: 'report',
              onPressed: () => IncidentReportingSheet.show(context, ref.read(navigationProvider.notifier).reportIncident),
              icon: const Icon(Icons.report_problem_outlined),
              label: const Text('Report'),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 18,
            child: TextButton.icon(
              style: TextButton.styleFrom(backgroundColor: Colors.white),
              onPressed: () async {
                await ref.read(navigationProvider.notifier).stopNavigation();
                if (context.mounted) Navigator.pop(context);
              },
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('End'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _ManeuverBanner extends StatelessWidget {
  const _ManeuverBanner({required this.routeName});
  final String routeName;

  @override
  Widget build(BuildContext context) => Material(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            const Icon(Icons.straight),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Continue for 1.2 km', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(routeName, maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
          ]),
        ),
      );
}

class _AlertBanner extends StatelessWidget {
  const _AlertBanner({required this.alert});
  final LiveAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = alert.kind == AlertKind.camera ? Colors.deepOrange : Colors.red;
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(alert.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            Text('${alert.distanceMeters.round()} m • ${alert.detail}', style: const TextStyle(color: Colors.white)),
          ])),
        ]),
      ),
    );
  }
}

class _SpeedHud extends StatelessWidget {
  const _SpeedHud({required this.speed, this.speedLimit});
  final int speed;
  final int? speedLimit;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xee101820),
        borderRadius: BorderRadius.circular(22),
        elevation: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$speed', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 44, height: .9)),
              const Text('km/h', style: TextStyle(color: Colors.white70)),
            ]),
            if (speedLimit != null) ...[
              const SizedBox(width: 24),
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: Colors.red, width: 5)),
                child: Text('$speedLimit', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              ),
            ],
          ]),
        ),
      );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
