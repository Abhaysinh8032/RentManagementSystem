import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'property_model.dart';

class PropertyRepository {
  final ApiClient apiClient;
  PropertyRepository({required this.apiClient});

  Future<List<PropertyModel>> listActive() => _listFrom(ApiEndpoints.properties);

  Future<List<PropertyModel>> listAllForAdmin() => _listFrom(ApiEndpoints.adminProperties);

  Future<PropertyModel> getById(int id) async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.propertyById(id));
      return PropertyModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<PropertyModel> create(Map<String, dynamic> body) async {
    try {
      final res = await apiClient.dio.post(ApiEndpoints.adminProperties, data: body);
      return PropertyModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<PropertyModel> update(int id, Map<String, dynamic> body) async {
    try {
      final res = await apiClient.dio.put(ApiEndpoints.adminPropertyById(id), data: body);
      return PropertyModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<PropertyModel> setActive(int id, bool active) async {
    try {
      final res = await apiClient.dio.put(
        ApiEndpoints.adminPropertyActive(id),
        queryParameters: {'active': active},
      );
      return PropertyModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<List<PropertyModel>> _listFrom(String path) async {
    try {
      final res = await apiClient.dio.get(path);
      final list = res.data['data'] as List;
      return list.map((e) => PropertyModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }
}
