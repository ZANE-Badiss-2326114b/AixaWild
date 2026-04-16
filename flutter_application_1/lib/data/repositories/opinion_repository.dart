import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/models/opinion.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

class OpinionRepository {
  final IApiClient _apiClient;

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
