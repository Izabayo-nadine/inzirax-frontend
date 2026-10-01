import 'package:geolocator/geolocator.dart';
import 'package:inzirax/core/geo.dart';

class DriverPosition {
  const DriverPosition({
    required this.point,
    required this.speedKph,
    required this.heading,
  });

  final GeoPoint point;
  final double speedKph;
  final double heading;

  factory DriverPosition.fromPosition(Position position) => DriverPosition(
        point: GeoPoint(position.latitude, position.longitude),
        speedKph: (position.speed * 3.6).clamp(0, 400).toDouble(),
        heading: position.heading.isFinite && position.heading >= 0 ? position.heading.toDouble() : 0,
      );

  Map<String, dynamic> toTelemetryJson() => {
        ...point.toJson(),
        'speed': speedKph,
        'bearing': heading.round().clamp(0, 360).toInt(),
      };
}
