import 'package:inzirax/core/geo.dart';

class RouteCandidate {
  const RouteCandidate({
    required this.id,
    required this.summary,
    required this.distanceKm,
    required this.durationMins,
    required this.speedCameraCount,
    required this.hasCongestion,
    required this.isRecommended,
    required this.polyline,
  });

  final String id;
  final String summary;
  final double distanceKm;
  final double durationMins;
  final int speedCameraCount;
  final bool hasCongestion;
  final bool isRecommended;
  final List<GeoPoint> polyline;

  factory RouteCandidate.fromJson(Map<String, dynamic> json) => RouteCandidate(
        id: json['route_id'] as String,
        summary: json['summary'] as String? ?? 'Recommended route',
        distanceKm: (json['distance_km'] as num).toDouble(),
        durationMins: (json['duration_mins'] as num).toDouble(),
        speedCameraCount: json['speed_camera_count'] as int? ?? 0,
        hasCongestion: json['has_congestion'] as bool? ?? false,
        isRecommended: json['is_recommended'] as bool? ?? false,
        polyline: (json['polyline'] as List<dynamic>)
            .map((point) => GeoPoint.fromJson(point as Map<String, dynamic>))
            .toList(growable: false),
      );
}
