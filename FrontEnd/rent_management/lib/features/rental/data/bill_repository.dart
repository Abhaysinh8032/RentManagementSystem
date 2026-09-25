import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import 'bill_model.dart';

class BillRepository {
  final ApiClient apiClient;
  BillRepository({required this.apiClient});

  Future<List<BillModel>> listMine() => _listFrom(ApiEndpoints.myBills);

  Future<List<BillModel>> listByRentalRequest(int rentalRequestId) =>
      _listFrom(ApiEndpoints.billsByRentalRequest(rentalRequestId));

  // Can be called more than once per bill (matches the backend's relaxed
  // guard) - resubmitting updates the reference and/or the full image set,
  // right up until the admin actually verifies it.
  Future<BillModel> claimPayment(int billId, {required String paymentReference, required List<String> proofImageUrls}) async {
    try {
      final res = await apiClient.dio.put(
        ApiEndpoints.billClaimPayment(billId),
        data: {'paymentReference': paymentReference, 'proofImageUrls': proofImageUrls},
      );
      return BillModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<BillModel> verify(int billId, {required bool approve, String? adminNote}) async {
    try {
      final res = await apiClient.dio.put(
        ApiEndpoints.adminBillVerify(billId),
        data: {'approve': approve, 'adminNote': adminNote},
      );
      return BillModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<BillModel> refund(int billId, {String? refundReference, String? adminNote}) async {
    try {
      final res = await apiClient.dio.put(
        ApiEndpoints.adminBillRefund(billId),
        data: {'refundReference': refundReference, 'adminNote': adminNote},
      );
      return BillModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }

  Future<List<BillModel>> _listFrom(String path) async {
    try {
      final res = await apiClient.dio.get(path);
      final list = res.data['data'] as List;
      return list.map((e) => BillModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }
}
