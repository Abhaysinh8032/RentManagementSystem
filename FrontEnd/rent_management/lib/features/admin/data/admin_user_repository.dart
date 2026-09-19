import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'admin_user_model.dart';

class AdminUserRepository {
  final ApiClient apiClient;
  AdminUserRepository({required this.apiClient});

  Future<List<AdminUserModel>> listPending() => _listFrom(ApiEndpoints.adminUsersPending);

  Future<List<AdminUserModel>> listAll() => _listFrom(ApiEndpoints.adminUsers);

  Future<AdminUserModel> decideApproval(int userId, bool approve) async {
    try {
      final res = await apiClient.dio.put(
        ApiEndpoints.adminUserApprove(userId),
        queryParameters: {'approve': approve},
      );
      return AdminUserModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<List<AdminUserModel>> _listFrom(String path) async {
    try {
      final res = await apiClient.dio.get(path);
      final list = res.data['data'] as List;
      return list.map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }
}
