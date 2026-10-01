import 'dart:async';

import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:inzirax/core/geo.dart';
import 'package:inzirax/models/driver_position.dart';

/// Configures native background tracking. The navigation controller remains the
/// single owner of telemetry transport, so foreground and background fixes use
/// the same WebSocket payload and alert pipeline.
class BackgroundLocationService {
  final _positions = StreamController<DriverPosition>.broadcast();
  bool _configured = false;

  Stream<DriverPosition> get positions => _positions.stream;

  Future<void> configure() async {
    if (_configured) return;
    _configured = true;
    bg.BackgroundGeolocation.onLocation((location) {
      final coords = location.coords;
      _positions.add(DriverPosition(
        point: _toPoint(coords.latitude, coords.longitude),
        speedKph: ((coords.speed ?? 0) * 3.6).clamp(0, 400).toDouble(),
        heading: (coords.heading ?? 0).clamp(0, 360).toDouble(),
      ));
    });
    await bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_NAVIGATION,
      distanceFilter: 5,
      stopOnTerminate: false,
      startOnBoot: true,
      foregroundService: true,
      notification: bg.Notification(
        title: 'Inzirax navigation is active',
        text: 'Sharing your location for route alerts',
      ),
    ));
  }

  Future<void> start() async {
    await configure();
    await bg.BackgroundGeolocation.start();
  }

  Future<void> stop() => bg.BackgroundGeolocation.stop();

  Future<void> dispose() async {
    await _positions.close();
  }
}

GeoPoint _toPoint(double latitude, double longitude) => GeoPoint(latitude, longitude);
