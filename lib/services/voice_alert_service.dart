import 'package:flutter_tts/flutter_tts.dart';

class VoiceAlertService {
  VoiceAlertService() {
    _tts.setLanguage('en-ZA');
    _tts.setSpeechRate(0.48);
  }

  final FlutterTts _tts = FlutterTts();
  String? _lastAlertId;

  Future<void> announce(String alertId, String message, {required bool enabled}) async {
    if (!enabled || _lastAlertId == alertId) return;
    _lastAlertId = alertId;
    await _tts.stop();
    await _tts.speak(message);
  }

  Future<void> dispose() => _tts.stop();
}
