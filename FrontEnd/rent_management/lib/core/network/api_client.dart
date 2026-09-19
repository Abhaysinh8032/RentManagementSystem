import 'package:dio/dio.dart';

import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';

class ApiClient {
  late final Dio dio;

  // Every protected endpoint added after auth needs this - auth's own
  // register/login calls don't need a token, so they were fine without it,
  // but everything from here on (properties, rentals, bills) is behind
  // Spring Security's authenticated() rule and needs Authorization: Bearer.
  ApiClient({required SecureStorageService secureStorage}) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await secureStorage.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }
}
