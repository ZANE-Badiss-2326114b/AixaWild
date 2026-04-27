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
    final payload = <String, dynamic>{};
    if (isLike != null) {
      payload['isLike'] = isLike;
    }
    if (labelSignalisation != null && labelSignalisation.trim().isNotEmpty) {
      payload['labelSignalisation'] = labelSignalisation.trim();
    }

    final response = await _apiClient.put(
      ApiEndpoints.opinionByPostAndUser(postId, userEmail),
      payload,
    );

    if (response is Map<String, dynamic>) {
      return Opinion.fromJson(response);
    }
    return null;
  }

  Future<void> addLike({
    required int postId,
    required String userEmail,
  }) async {
    try {
      await upsertOpinion(postId: postId, userEmail: userEmail, isLike: true);
      return;
    } catch (_) {
      // Try route variant for APIs exposing dedicated like endpoints.
    }

    try {
      await _apiClient.put(
        ApiEndpoints.opinionLikeByPostAndUser(postId, userEmail),
        const <String, dynamic>{},
      );
      return;
    } catch (_) {
      // Fallback to POST for some backends.
    }

    await _apiClient.post(
      ApiEndpoints.opinionLikeByPostAndUser(postId, userEmail),
      const <String, dynamic>{},
    );
  }

  Future<void> removeLike({
    required int postId,
    required String userEmail,
  }) async {
    try {
      await _apiClient.delete(ApiEndpoints.opinionLikeByPostAndUser(postId, userEmail));
      return;
    } catch (_) {
      // Some APIs only support upsert on generic opinion route.
    }

    await upsertOpinion(postId: postId, userEmail: userEmail, isLike: false);
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
