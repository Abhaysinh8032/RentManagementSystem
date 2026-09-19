import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'rental_model.dart';

class RentalRepository {
  final ApiClient apiClient;
  RentalRepository({required this.apiClient});

  Future<RentalRequestModel> createRequest({
    required int propertyId,
    required int quantity,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final res = await apiClient.dio.post(
        ApiEndpoints.rentalRequests,
        data: {
          'propertyId': propertyId,
          'quantity': quantity,
          'startDate': _formatDate(startDate),
          'endDate': _formatDate(endDate),
        },
      );
      return RentalRequestModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<List<RentalRequestModel>> listMine() => _listFrom(ApiEndpoints.myRentalRequests);

  Future<List<RentalRequestModel>> listAllForAdmin({String? status}) => _listFrom(
        ApiEndpoints.adminRentalRequests,
        queryParameters: status != null ? {'status': status} : null,
      );

  Future<RentalRequestModel> getById(int id) async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.rentalRequestById(id));
      return RentalRequestModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<RentalRequestModel> requestReturn(int id) async {
    try {
      final res = await apiClient.dio.put(ApiEndpoints.rentalRequestReturnRequest(id));
      return RentalRequestModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<RentalRequestModel> decide(int id, {required bool approve, String? adminNote}) async {
    try {
      final res = await apiClient.dio.put(
        ApiEndpoints.adminRentalRequestDecision(id),
        data: {'approve': approve, 'adminNote': adminNote},
      );
      return RentalRequestModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<RentalRequestModel> decideReturn(int id, {required bool approve, bool damaged = false, String? adminNote}) async {
    try {
      final res = await apiClient.dio.put(
        ApiEndpoints.adminRentalRequestReturnDecision(id),
        data: {'approve': approve, 'damaged': damaged, 'adminNote': adminNote},
      );
      return RentalRequestModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<List<RentalRequestModel>> _listFrom(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final res = await apiClient.dio.get(path, queryParameters: queryParameters);
      final list = res.data['data'] as List;
      return list.map((e) => RentalRequestModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
