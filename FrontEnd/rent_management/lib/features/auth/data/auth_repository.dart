import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Thrown with the backend's own ApiResponse.message so the UI can show
/// exactly what the server said (e.g. "An account with this email already exists").
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class LoginResult {
  final String token;
  final int userId;
  final String name;
  final String email;
  final String role;
  final String status;

  LoginResult({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) => LoginResult(
        token: json['token'] as String,
        userId: json['userId'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
      );
}

class AuthRepository {
  final ApiClient apiClient;
  final SecureStorageService secureStorage;

  AuthRepository({required this.apiClient, required this.secureStorage});

  /// Returns the backend's success message (e.g. "Registration successful.
  /// Your account is pending admin approval.") to show on the sign-in screen.
  Future<String> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );
      return response.data['message'] as String? ?? 'Registration successful.';
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await apiClient.dio.post(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      final result = LoginResult.fromJson(response.data['data'] as Map<String, dynamic>);
      await secureStorage.saveToken(result.token);
      return result;
    } on DioException catch (e) {
      throw ApiException(_extractMessage(e));
    }
  }

  /// Sprint 1 has no server-side session to invalidate (JWTs are stateless),
  /// so logging out just means wiping the locally stored token.
  Future<void> logout() async {
    await secureStorage.clearToken();
  }

  String _extractMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return 'Something went wrong. Please check your connection and try again.';
  }
}
