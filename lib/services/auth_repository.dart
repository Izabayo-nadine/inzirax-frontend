import 'package:dio/dio.dart';
import 'package:inzirax/core/app_config.dart';
import 'package:inzirax/core/app_exception.dart';

/// Authentication is intentionally separate from navigation UI so products can
/// supply their preferred onboarding flow and persist the returned JWT through
/// `SessionController.setAccessToken`.
class AuthRepository {
  AuthRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: '${AppConfig.apiUrl}/api/v1',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  final Dio _dio;

  Future<String> login({required String phoneNumber, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: FormData.fromMap({'username': phoneNumber, 'password': password}),
      );
      final token = response.data?['access_token'] as String?;
      if (token == null || token.isEmpty) throw const AppException('The server did not return an access token.');
      return token;
    } on DioException catch (error) {
      throw AppException('Sign-in failed: ${error.response?.data?['detail'] ?? error.message}');
    }
  }

  Future<String> register({required String fullName, required String phoneNumber, required String password}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/auth/register', data: {
        'full_name': fullName,
        'phone_number': phoneNumber,
        'password': password,
      });
      final token = response.data?['access_token'] as String?;
      if (token == null || token.isEmpty) throw const AppException('The server did not return an access token.');
      return token;
    } on DioException catch (error) {
      throw AppException('Registration failed: ${error.response?.data?['detail'] ?? error.message}');
    }
  }
}
