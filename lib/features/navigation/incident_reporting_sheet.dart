import 'package:flutter/material.dart';
import 'package:inzirax/services/incident_repository.dart';

class IncidentReportingSheet extends StatelessWidget {
  const IncidentReportingSheet({super.key, required this.onReport});
  final Future<void> Function(IncidentType) onReport;

  static Future<void> show(BuildContext context, Future<void> Function(IncidentType) onReport) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (_) => IncidentReportingSheet(onReport: onReport),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Report incident', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          const Text('Your current coordinates will be sent immediately.'),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.5,
            shrinkWrap: true,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: IncidentType.values
                .map((type) => OutlinedButton.icon(
                      onPressed: () async {
                        await onReport(type);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: Icon(_icon(type)),
                      label: Text(_title(type)),
                    ))
                .toList(growable: false),
          ),
        ]),
      );

  IconData _icon(IncidentType type) => switch (type) {
        IncidentType.congestion => Icons.traffic,
        IncidentType.accident => Icons.car_crash,
        IncidentType.roadblock => Icons.block,
        IncidentType.hazard => Icons.warning_amber,
      };

  String _title(IncidentType type) => '${type.name[0].toUpperCase()}${type.name.substring(1)}';
}
