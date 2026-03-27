import '../api/api_client.dart';
import '../models/opinion.dart';
import '../utils/api_endpoints.dart';

class OpinionRepository {
  final ApiClient _apiClient;

  OpinionRepository(this._apiClient);

  Future<Opinion?> upsertOpinion({
    required int postId,
    required String userEmail,
    bool? isLike,
    String? labelSignalisation,
  }) async {
    final payload = <String, dynamic>{
      'isLike': isLike,
      'labelSignalisation': labelSignalisation,
    };

    final response = await _apiClient.put(
      ApiEndpoints.opinionByPostAndUser(postId, userEmail),
      payload,
    );

    if (response is Map<String, dynamic>) {
      return Opinion.fromJson(response);
    }
    return null;
  }

  Future<void> removeLike({
    required int postId,
    required String userEmail,
  }) async {
    await _apiClient.delete(ApiEndpoints.opinionLikeByPostAndUser(postId, userEmail));
  }

  Future<void> removeSignalement({
    required int postId,
    required String userEmail,
  }) async {
    await _apiClient.delete(
      ApiEndpoints.opinionSignalementByPostAndUser(postId, userEmail),
    );
  }
}
