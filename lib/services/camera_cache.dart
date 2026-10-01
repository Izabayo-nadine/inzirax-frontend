import 'package:hive/hive.dart';

/// Lightweight offline mirror of camera payloads last received from the API.
class CameraCache {
  CameraCache._();
  static const _boxName = 'speed_camera_cache';
  static late Box<Map> _box;

  static Future<void> open() async {
    _box = await Hive.openBox<Map>(_boxName);
  }

  static Future<void> putAll(List<Map<String, dynamic>> cameras) async {
    await _box.putAll({for (final camera in cameras) camera['id'] as String: camera});
  }

  static List<Map<String, dynamic>> all() => _box.values
      .map((camera) => Map<String, dynamic>.from(camera))
      .toList(growable: false);
}
