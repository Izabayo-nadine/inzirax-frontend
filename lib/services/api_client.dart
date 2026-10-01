import 'package:dio/dio.dart';
import 'package:inzirax/core/app_config.dart';
import 'package:inzirax/core/app_exception.dart';

class ApiClient {
  ApiClient(this._readToken)
      : _dio = Dio(BaseOptions(
          baseUrl: '${AppConfig.apiUrl}/api/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Accept': 'application/json'},
        ));

  final String? Function() _readToken;
  final Dio _dio;

  Options get _authOptions {
    final token = _readToken();
    return Options(headers: token == null ? null : {'Authorization': 'Bearer $token'});
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body, options: _authOptions);
      return response.data ?? const {};
    } on DioException catch (error) {
      final detail = error.response?.data is Map ? (error.response?.data['detail'] ?? error.message) : error.message;
      throw AppException('Request failed: $detail');
    }
  }

  Future<List<dynamic>> getList(String path) async {
    try {
      final response = await _dio.get<List<dynamic>>(path, options: _authOptions);
      return response.data ?? const [];
    } on DioException catch (error) {
      throw AppException('Request failed: ${error.message}');
    }
  }
}
