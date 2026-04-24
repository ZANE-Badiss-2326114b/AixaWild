import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/models/post.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

class PostRepository {
	final IApiClient _apiClient;

	PostRepository(this._apiClient);

	Future<List<Post>> getAllPosts() async {
		final response = await _apiClient.get(ApiEndpoints.posts);
		if (response is List) {
			return response
					.whereType<Map<String, dynamic>>()
					.map(Post.fromJson)
					.toList();
		}
		return <Post>[];
	}

	Future<Post?> getPostById(int postId) async {
		final response = await _apiClient.get(ApiEndpoints.postById(postId));
		if (response is Map<String, dynamic>) {
			return Post.fromJson(response);
		}
		return null;
	}

	Future<Post?> createPost({
		required String authorEmail,
		required String title,
		String? content,
		String? locationName,
		double? latitude,
		double? longitude,
	}) async {
		final payload = <String, dynamic>{
			'authorEmail': authorEmail,
			'title': title,
			'content': content,
		};

		if (locationName != null && locationName.trim().isNotEmpty) {
			payload['locationName'] = locationName.trim();
		}
		if (latitude != null) {
			payload['latitude'] = latitude;
			payload['lat'] = latitude;
		}
		if (longitude != null) {
			payload['longitude'] = longitude;
			payload['lng'] = longitude;
		}

		final response = await _apiClient.post(ApiEndpoints.posts, payload);
		if (response is Map<String, dynamic>) {
			return Post.fromJson(response);
		}
		return null;
	}

	Future<Post?> updatePost({
		required int postId,
		required String authorEmail,
		required String title,
		String? content,
		String? locationName,
		double? latitude,
		double? longitude,
	}) async {
		final payload = <String, dynamic>{
			'authorEmail': authorEmail,
			'title': title,
			'content': content,
		};

		if (locationName != null && locationName.trim().isNotEmpty) {
			payload['locationName'] = locationName.trim();
		}
		if (latitude != null) {
			payload['latitude'] = latitude;
			payload['lat'] = latitude;
		}
		if (longitude != null) {
			payload['longitude'] = longitude;
			payload['lng'] = longitude;
		}

		final response = await _apiClient.put(ApiEndpoints.postById(postId), payload);
		if (response is Map<String, dynamic>) {
			return Post.fromJson(response);
		}
		return null;
	}

	Future<void> deletePost(int postId) async {
		await _apiClient.delete(ApiEndpoints.postById(postId));
	}
}