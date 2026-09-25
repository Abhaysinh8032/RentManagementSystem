import 'dart:io';

import 'package:dio/dio.dart';

import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';

/// Uploads THROUGH the backend now, not directly to any storage provider.
/// The backend decides which provider handles which image type - Cloudinary
/// for property images, Supabase Storage for payment proofs - and holds the
/// real provider credentials (api secrets, service role keys) entirely
/// server-side. This class just does a normal authenticated multipart POST,
/// same pattern as every other repository in the app, through the shared
/// ApiClient (so the JWT interceptor attaches automatically).
class ImageUploadService {
  final ApiClient apiClient;
  ImageUploadService({required this.apiClient});

  Future<String> uploadPropertyImage(File file) => _upload(file, ApiEndpoints.adminUploadPropertyImage);

  Future<String> uploadPaymentProofImage(File file) => _upload(file, ApiEndpoints.uploadPaymentProofImage);

  Future<String> _upload(File file, String endpoint) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: file.path.split('/').last),
      });
      final response = await apiClient.dio.post(endpoint, data: formData);
      return response.data['data']['url'] as String;
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }
}
