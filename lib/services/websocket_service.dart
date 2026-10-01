import 'dart:async';
import 'dart:convert';

import 'package:inzirax/core/app_config.dart';
import 'package:inzirax/models/driver_position.dart';
import 'package:inzirax/models/live_alert.dart';
import 'package:inzirax/services/camera_cache.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _alerts = StreamController<List<LiveAlert>>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  String? _token;
  bool _disposed = false;
  int _attempt = 0;
  Timer? _retry;

  Stream<List<LiveAlert>> get alerts => _alerts.stream;
  Stream<bool> get connection => _connection.stream;

  Future<void> connect(String token) async {
    _token = token;
    _retry?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    try {
      final channel = WebSocketChannel.connect(AppConfig.websocketUri(token));
      _channel = channel;
      await channel.ready;
      _attempt = 0;
      _connection.add(true);
      _subscription = channel.stream.listen(_onMessage, onDone: _handleDisconnect, onError: (_) => _handleDisconnect());
    } catch (_) {
      _handleDisconnect();
    }
  }

  void sendPosition(DriverPosition position) {
    _channel?.sink.add(jsonEncode(position.toTelemetryJson()));
  }

  void _onMessage(dynamic event) {
    final payload = jsonDecode(event as String) as Map<String, dynamic>;
    if (payload['type'] != 'location_ack') return;
    final cameras = (payload['cameras'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    CameraCache.putAll(cameras);
    final alerts = <LiveAlert>[
      ...cameras.map(LiveAlert.camera),
      ...(payload['incidents'] as List<dynamic>? ?? const [])
          .map((item) => LiveAlert.incident(item as Map<String, dynamic>)),
    ]..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    _alerts.add(alerts);
  }

  void _handleDisconnect() {
    _connection.add(false);
    if (_disposed || _token == null) return;
    final seconds = 1 << _attempt.clamp(0, 5).toInt();
    _attempt++;
    _retry?.cancel();
    _retry = Timer(Duration(seconds: seconds), () => connect(_token!));
  }

  Future<void> dispose() async {
    _disposed = true;
    _retry?.cancel();
    await _subscription?.cancel();
    await _channel?.sink.close();
    await _alerts.close();
    await _connection.close();
  }
}
