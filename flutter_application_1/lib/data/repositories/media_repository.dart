import 'dart:typed_data';

import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/api/media/media_api_service.dart';
import 'package:flutter_application_1/data/models/media.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

class MediaRepository {
  final IApiClient _apiClient;
  late final MediaApiService _mediaApiService;

  MediaRepository(this._apiClient) {
    _mediaApiService = MediaApiService(_apiClient);
  }

  Future<List<Media>> getByPostId(int postId) async {
    final response = await _apiClient.get(ApiEndpoints.postMedia(postId));
    if (response is List) {
      return response
          .whereType<Map<String, dynamic>>()
          .map(Media.fromJson)
          .toList();
    }
    return <Media>[];
  }

  Future<Media?> create({
    required int postId,
    required String url,
  }) async {
    final result = await _mediaApiService.createMediaFromUrl(
      postId: postId,
      url: url,
    );
    return result.media;
  }

  Future<void> delete(int mediaId) async {
    await _apiClient.delete(ApiEndpoints.mediaById(mediaId));
  }

  Future<Media?> uploadMedia({
    required int postId,
    required Uint8List mediaBytes,
    required String fileName,
    String? mimeType,
    void Function(UploadResult update)? onUpdate,
  }) async {
    final result = await _mediaApiService.uploadMediaFile(
      postId: postId,
      mediaBytes: mediaBytes,
      fileName: fileName,
      mimeType: mimeType,
      onUpdate: onUpdate,
    );
    return result.media;
  }

  Future<UploadResult> uploadMediaWithResult({
    required int postId,
    required Uint8List mediaBytes,
    required String fileName,
    String? mimeType,
    void Function(UploadResult update)? onUpdate,
  }) async {
    return _mediaApiService.uploadMediaFile(
      postId: postId,
      mediaBytes: mediaBytes,
      fileName: fileName,
      mimeType: mimeType,
      onUpdate: onUpdate,
    );
  }
}
