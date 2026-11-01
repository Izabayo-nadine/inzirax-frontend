import 'package:flutter/material.dart';
import 'package:inzirax/core/app_config.dart';
import 'package:inzirax/models/driver_position.dart';
import 'package:inzirax/models/route_candidate.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class DriverMap extends StatefulWidget {
  const DriverMap({super.key, required this.position, this.route, this.followDriver = false});
  final DriverPosition? position;
  final RouteCandidate? route;
  final bool followDriver;

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  MapboxMap? _map;
  PointAnnotationManager? _points;
  PolylineAnnotationManager? _lines;

  @override
  void didUpdateWidget(covariant DriverMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_map != null && (oldWidget.position != widget.position || oldWidget.route != widget.route)) {
      _render();
    }
  }

  Future<void> _onMapCreated(MapboxMap map) async {
    _map = map;
    _points = await map.annotations.createPointAnnotationManager();
    _lines = await map.annotations.createPolylineAnnotationManager();
    await _render();
  }

  Future<void> _render() async {
    final map = _map;
    final position = widget.position;
    if (map == null || position == null) return;
    await _points?.deleteAll();
    await _lines?.deleteAll();
    final point = Point(coordinates: Position(position.point.longitude, position.point.latitude));
    await _points?.create(PointAnnotationOptions(
      geometry: point,
      iconColor: 0xff00d4aa, // teal
      iconSize: 1.4,
    ));
    final route = widget.route;
    if (route != null) {
      await _lines?.create(PolylineAnnotationOptions(
        geometry: LineString(coordinates: route.polyline.map((p) => Position(p.longitude, p.latitude)).toList()),
        lineColor: 0xff6c63ff, // electric violet
        lineWidth: 6,
        lineOpacity: 0.9,
      ));
    }
    await map.setCamera(CameraOptions(
      center: point,
      zoom: widget.followDriver ? 16.5 : 14,
      bearing: widget.followDriver ? position.heading : 0,
      pitch: widget.followDriver ? 
      
      
      55 : 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.mapboxAccessToken.isEmpty) {
      return Container(
        color: const Color(0xff0d0f14),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map_outlined, color: Color(0xff8b949e), size: 48),
              SizedBox(height: 12),
              Text(
                'Set MAPBOX_ACCESS_TOKEN to show the map.',
                style: TextStyle(color: Color(0xff8b949e), fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    final point = widget.position?.point;
    return MapWidget(
      key: const ValueKey('inzirax-map'),
      cameraOptions: CameraOptions(
        center: point == null
            ? null
            : Point(
                coordinates:
                    Position(point.longitude, point.latitude)),
        zoom: point == null ? 3 : 14,
      ),
      styleUri: MapboxStyles.DARK,
      onMapCreated: _onMapCreated,
    );
  }

  @override
  void dispose() {
    _points?.deleteAll();
    _lines?.deleteAll();
    super.dispose();
  }
}
