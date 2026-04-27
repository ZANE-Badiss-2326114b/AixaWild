import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/models/post.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

/// Repository des posts orienté source distante.
///
/// Expose les opérations CRUD post via l'API en isolant la couche UI des
/// détails HTTP.
class PostRepository {
  final IApiClient _apiClient;

  /// Construit le repository post.
  ///
  /// [apiClient] exécute les appels HTTP.
  PostRepository(this._apiClient);

  /// Retourne tous les posts depuis l'API.
  ///
  /// Retourne une liste de [Post], vide si réponse invalide.
  Future<List<Post>> getAllPosts() async {
    final response = await _apiClient.get(ApiEndpoints.posts);
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
    }
    return <Post>[];
  }

  /// Retourne le détail d'un post.
  ///
  /// [postId] identifie le post cible.
  /// Retourne un [Post] si trouvé, sinon `null`.
  Future<Post?> getPostById(int postId) async {
    final response = await _apiClient.get(ApiEndpoints.postById(postId));
    if (response is Map<String, dynamic>) {
      return Post.fromJson(response);
    }
    return null;
  }

  /// Crée un post distant.
  ///
  /// [authorEmail] email de l'auteur.
  /// [title] titre du post.
  /// [content] contenu textuel optionnel.
  /// [locationName] nom de localisation optionnel.
  /// [latitude] latitude optionnelle.
  /// [longitude] longitude optionnelle.
  /// Retourne le [Post] créé, sinon `null`.
  Future<Post?> createPost({required String authorEmail, required String title, String? content, String? locationName, double? latitude, double? longitude}) async {
    final payload = <String, dynamic>{'authorEmail': authorEmail, 'title': title, 'content': content};

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

  /// Met à jour un post distant.
  ///
  /// [postId] identifie le post cible.
  /// [authorEmail] email de l'auteur.
  /// [title] nouveau titre.
  /// [content] nouveau contenu optionnel.
  /// [locationName] nom de localisation optionnel.
  /// [latitude] latitude optionnelle.
  /// [longitude] longitude optionnelle.
  /// Retourne le [Post] mis à jour, sinon `null`.
  Future<Post?> updatePost({required int postId, required String authorEmail, required String title, String? content, String? locationName, double? latitude, double? longitude}) async {
    final payload = <String, dynamic>{'authorEmail': authorEmail, 'title': title, 'content': content};

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

  /// Supprime un post distant.
  ///
  /// [postId] identifie la ressource à supprimer.
  /// Retourne `Future<void>`.
  Future<void> deletePost(int postId) async {
    await _apiClient.delete(ApiEndpoints.postById(postId));
  }
}
