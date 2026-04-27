import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/models/opinion.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

/// Repository des opinions (likes/signalements) orienté API.
///
/// Fournit des opérations CRUD ciblées pour les interactions utilisateur sur
/// les posts.
class OpinionRepository {
  final IApiClient _apiClient;

  /// Construit le repository opinions.
  ///
  /// [apiClient] exécute les appels HTTP.
  OpinionRepository(this._apiClient);

  /// Charge toutes les opinions depuis l'API.
  ///
  /// Retourne une liste de [Opinion], vide si réponse invalide.
  Future<List<Opinion>> getAllOpinions() async {
    final response = await _apiClient.get(ApiEndpoints.opinions);

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().map(Opinion.fromJson).toList();
    }

    return <Opinion>[];
  }

  /// Crée ou met à jour une opinion utilisateur.
  ///
  /// [postId] identifie le post cible.
  /// [userEmail] identifie l'auteur de l'opinion.
  /// [isLike] indique une intention de like.
  /// [labelSignalisation] précise le motif de signalement.
  /// Retourne l'[Opinion] persistée, sinon `null`.
  Future<Opinion?> upsertOpinion({required int postId, required String userEmail, bool? isLike, String? labelSignalisation}) async {
    final payload = <String, dynamic>{'isLike': isLike, 'labelSignalisation': labelSignalisation};

    final response = await _apiClient.put(ApiEndpoints.opinionByPostAndUser(postId, userEmail), payload);

    if (response is Map<String, dynamic>) {
      return Opinion.fromJson(response);
    }
    return null;
  }

  /// Supprime le like d'un utilisateur sur un post.
  ///
  /// [postId] identifie le post cible.
  /// [userEmail] identifie l'utilisateur cible.
  /// Retourne `Future<void>`.
  Future<void> removeLike({required int postId, required String userEmail}) async {
    await _apiClient.delete(ApiEndpoints.opinionLikeByPostAndUser(postId, userEmail));
  }

  /// Supprime le signalement d'un utilisateur sur un post.
  ///
  /// [postId] identifie le post cible.
  /// [userEmail] identifie l'utilisateur cible.
  /// Retourne `Future<void>`.
  Future<void> removeSignalement({required int postId, required String userEmail}) async {
    await _apiClient.delete(ApiEndpoints.opinionSignalementByPostAndUser(postId, userEmail));
  }
}
