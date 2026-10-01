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
  LineAnnotationManager? _lines;

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
    _lines = await map.annotations.createLineAnnotationManager();
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
      iconColor: 0xff006d77,
      iconSize: 1.4,
    ));
    final route = widget.route;
    if (route != null) {
      await _lines?.create(LineAnnotationOptions(
        geometry: LineString(coordinates: route.polyline.map((p) => Position(p.longitude, p.latitude)).toList()),
        lineColor: 0xff0077ff,
        lineWidth: 6,
        lineOpacity: 0.85,
      ));
    }
    await map.setCamera(CameraOptions(
      center: point,
      zoom: widget.followDriver ? 16.5 : 14,
      bearing: widget.followDriver ? position.heading : 0,
      pitch: widget.followDriver ? 55 : 0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (AppConfig.mapboxAccessToken.isEmpty) {
      return const ColoredBox(
        color: Color(0xffe8f1f2),
        child: Center(child: Text('Set MAPBOX_ACCESS_TOKEN to show the map.')),
      );
    }
    final point = widget.position?.point;
    return MapWidget(
      key: const ValueKey('inzirax-map'),
      cameraOptions: CameraOptions(
        center: point == null ? null : Point(coordinates: Position(point.longitude, point.latitude)),
        zoom: point == null ? 3 : 14,
      ),
      styleUri: MapboxStyles.MAPBOX_STREETS,
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
