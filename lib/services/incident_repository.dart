import 'package:inzirax/core/geo.dart';
import 'package:inzirax/services/api_client.dart';

enum IncidentType { congestion, accident, roadblock, hazard }

class IncidentRepository {
  IncidentRepository(this._api);
  final ApiClient _api;

  Future<void> report(IncidentType type, GeoPoint location) async {
    await _api.post('/incidents', {
      'incident_type': type.name.toUpperCase(),
      'location': location.toJson(),
      'severity': type == IncidentType.accident || type == IncidentType.roadblock ? 'HIGH' : 'MEDIUM',
      'expires_at': DateTime.now().toUtc().add(const Duration(hours: 2)).toIso8601String(),
    });
  }
}
