import 'dart:io';

import 'package:dio/dio.dart';
import 'package:rent_management/core/network/api_client.dart';
import 'package:rent_management/core/network/api_endpoints.dart';
import 'package:rent_management/core/network/api_exception.dart';

/// Uploads directly to Supabase Storage using its plain REST API, so no new
/// heavy SDK dependency (supabase_flutter) is needed - just Dio, which the
/// app already uses everywhere else.
///
/// *** YOU MUST FILL THESE IN before this works ***
/// From your Supabase project: Settings -> API gives you the URL and anon key.
/// Storage -> create a bucket (e.g. "property-images") and mark it PUBLIC
/// (or attach a public-read policy) so the uploaded URL is viewable without
/// auth - the app only ever sends the resulting URL to the backend as a plain
/// string, it never re-authenticates to fetch the image.
class ImageUploadService {
  static const String supabaseUrl =
      'https://kkuopxwmmosdmfnphhsm.supabase.co/storage/v1';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtrdW9weHdtbW9zZG1mbnBoaHNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkyNjc4MzIsImV4cCI6MjEwNDg0MzgzMn0.zDcQCHs9cud278spXsJWpqbBGWhB4yP0tjxNrwVVOKQ';
  static const String bucketName = 'payment-proofs';

  final ApiClient apiClient;
  ImageUploadService({required this.apiClient});

  Future<String> uploadPropertyImage(File file) =>
      _upload(file, ApiEndpoints.adminUploadPropertyImage);

  Future<String> uploadPaymentProofImage(File file) =>
      _upload(file, ApiEndpoints.uploadPaymentProofImage);

  Future<String> _upload(File file, String endpoint) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      final response = await apiClient.dio.post(endpoint, data: formData);
      return response.data['data']['url'] as String;
    } on DioException catch (e) {
      throw ApiException(extractErrorMessage(e));
    }
  }
}
