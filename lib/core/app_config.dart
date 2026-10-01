class AppConfig {
  AppConfig._();

  /// Android Emulator uses 10.0.2.2 to reach the host machine.
  static const apiUrl = String.fromEnvironment(
    'INZIRAX_API_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const mapboxAccessToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  static Uri get apiBaseUri => Uri.parse(apiUrl);

  static Uri websocketUri(String token) {
    final base = apiBaseUri;
    return base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '${base.path}/ws/driver/location'.replaceAll('//', '/'),
      queryParameters: {'token': token},
    );
  }
}
