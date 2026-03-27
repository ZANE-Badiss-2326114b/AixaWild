import '../api/api_client.dart';
import '../models/post.dart';
import '../utils/api_endpoints.dart';

class PostRepository {
	final ApiClient _apiClient;

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
	}) async {
		final payload = <String, dynamic>{
			'authorEmail': authorEmail,
			'title': title,
			'content': content,
		};

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
	}) async {
		final payload = <String, dynamic>{
			'authorEmail': authorEmail,
			'title': title,
			'content': content,
		};

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