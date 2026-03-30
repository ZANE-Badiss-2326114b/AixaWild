import '../api/api_client.dart';
import '../models/media.dart';
import '../utils/api_endpoints.dart';

class MediaRepository {
  final ApiClient _apiClient;

  MediaRepository(this._apiClient);

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
    final payload = <String, dynamic>{
      'postId': postId,
      'url': url,
    };

    final response = await _apiClient.post(ApiEndpoints.postMedia(postId), payload);
    if (response is Map<String, dynamic>) {
      return Media.fromJson(response);
    }
    return null;
  }

  Future<void> delete(int mediaId) async {
    await _apiClient.delete(ApiEndpoints.mediaById(mediaId));
  }
}
