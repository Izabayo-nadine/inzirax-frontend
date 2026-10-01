import 'package:dio/dio.dart';
import 'package:inzirax/core/app_config.dart';
import 'package:inzirax/core/app_exception.dart';
import 'package:inzirax/core/geo.dart';
import 'package:inzirax/models/place_suggestion.dart';
import 'package:inzirax/models/route_candidate.dart';
import 'package:inzirax/services/api_client.dart';

class RouteRepository {
  RouteRepository(this._api);
  final ApiClient _api;
  final Dio _geocoding = Dio();

  Future<List<RouteCandidate>> plan({
    required GeoPoint origin,
    required String originName,
    required PlaceSuggestion destination,
  }) async {
    final response = await _api.post('/trips/plan-routes', {
      'origin_name': originName,
      'origin_location': origin.toJson(),
      'destination_name': destination.name,
      'destination_location': destination.point.toJson(),
    });
    return (response['candidate_routes'] as List<dynamic>)
        .map((route) => RouteCandidate.fromJson(route as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<List<PlaceSuggestion>> searchPlaces(String query, GeoPoint? proximity) async {
    if (query.trim().length < 3) return const [];
    if (AppConfig.mapboxAccessToken.isEmpty) {
      throw const AppException('Set MAPBOX_ACCESS_TOKEN to enable place search.');
    }
    try {
      final response = await _geocoding.get<Map<String, dynamic>>(
        'https://api.mapbox.com/search/geocode/v6/forward',
        queryParameters: {
          'q': query,
          'access_token': AppConfig.mapboxAccessToken,
          if (proximity != null) 'proximity': '${proximity.longitude},${proximity.latitude}',
          'limit': 5,
        },
      );
      final features = response.data?['features'] as List<dynamic>? ?? const [];
      return features
          .map((feature) => PlaceSuggestion.fromMapbox(feature as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (error) {
      throw AppException('Could not search places: ${error.message}');
    }
  }
}
