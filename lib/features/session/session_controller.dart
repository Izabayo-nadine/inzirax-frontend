import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionController extends StateNotifier<String?> {
  SessionController() : super(null) {
    _restore();
  }

  static const _storage = FlutterSecureStorage();
  static const _key = 'access_token';

  Future<void> _restore() async => state = await _storage.read(key: _key);
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: _key, value: token);
    state = token;
  }

  Future<void> clear() async {
    await _storage.delete(key: _key);
    state = null;
  }
}

final sessionProvider = StateNotifierProvider<SessionController, String?>((ref) => SessionController());
