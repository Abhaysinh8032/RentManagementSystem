import 'package:dio/dio.dart';

/// Shared across every repository added after auth, so the backend's own
/// ApiResponse.message always surfaces verbatim in the UI.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

String extractErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['message'] != null) {
    return data['message'].toString();
  }
  return 'Something went wrong. Please check your connection and try again.';
}
