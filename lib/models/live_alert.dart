import 'package:inzirax/core/geo.dart';

enum AlertKind { camera, incident }

class LiveAlert {
  const LiveAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.detail,
    required this.distanceMeters,
    required this.location,
    this.speedLimit,
  });

  final String id;
  final AlertKind kind;
  final String title;
  final String detail;
  final double distanceMeters;
  final GeoPoint location;
  final int? speedLimit;

  factory LiveAlert.camera(Map<String, dynamic> json) => LiveAlert(
        id: json['id'] as String,
        kind: AlertKind.camera,
        title: 'Speed camera ahead',
        detail: json['name'] as String? ?? 'Speed camera',
        distanceMeters: (json['distance_meters'] as num).toDouble(),
        speedLimit: json['speed_limit'] as int?,
        location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      );

  factory LiveAlert.incident(Map<String, dynamic> json) => LiveAlert(
        id: json['id'] as String,
        kind: AlertKind.incident,
        title: '${json['type']} ahead',
        detail: 'Traffic incident reported',
        distanceMeters: (json['distance_meters'] as num).toDouble(),
        location: GeoPoint.fromJson(json['location'] as Map<String, dynamic>),
      );
}
