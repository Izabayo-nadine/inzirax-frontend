import 'package:inzirax/core/geo.dart';

class PlaceSuggestion {
  const PlaceSuggestion({required this.name, required this.point});
  final String name;
  final GeoPoint point;

  factory PlaceSuggestion.fromMapbox(Map<String, dynamic> json) {
    final coordinates = json['geometry']?['coordinates'] as List<dynamic>?;
    if (coordinates == null || coordinates.length < 2) {
      throw const FormatException('Geocoder result has no point geometry.');
    }
    return PlaceSuggestion(
      name: json['full_address'] as String? ?? json['name'] as String? ?? 'Unnamed place',
      point: GeoPoint((coordinates[1] as num).toDouble(), (coordinates[0] as num).toDouble()),
    );
  }
}
