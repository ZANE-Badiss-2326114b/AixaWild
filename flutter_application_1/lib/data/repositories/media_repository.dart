import 'dart:typed_data';

import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/api/media/media_api_service.dart';
import 'package:flutter_application_1/data/models/media.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

/// Repository média orienté API.
///
/// Ce repository délègue la logique d'upload/création à [MediaApiService]
/// et expose une API simplifiée à la couche présentation.
class MediaRepository {
  final IApiClient _apiClient;
  late final MediaApiService _mediaApiService;

  /// Construit le repository média.
  ///
  /// [apiClient] est le client HTTP utilisé par le service média.
  MediaRepository(this._apiClient) {
    _mediaApiService = MediaApiService(_apiClient);
  }

  /// Charge les médias d'un post.
  ///
  /// [postId] identifie le post cible.
  /// Retourne la liste des [Media], vide si réponse invalide.
  Future<List<Media>> getByPostId(int postId) async {
    final response = await _apiClient.get(ApiEndpoints.postMedia(postId));
    if (response is List) {
      return response.whereType<Map<String, dynamic>>().map(Media.fromJson).toList();
    }
    return <Media>[];
  }

  /// Crée un média à partir d'une URL distante.
  ///
  /// [postId] identifie le post cible.
  /// [url] est l'URL source du média.
  /// Retourne le [Media] créé, sinon `null`.
  Future<Media?> create({required int postId, required String url}) async {
    final result = await _mediaApiService.createMediaFromUrl(postId: postId, url: url);
    return result.media;
  }

  /// Supprime un média par son identifiant.
  ///
  /// [mediaId] identifie la ressource à supprimer.
  /// Retourne `Future<void>`.
  Future<void> delete(int mediaId) async {
    await _apiClient.delete(ApiEndpoints.mediaById(mediaId));
  }

  /// Upload un fichier média et retourne la ressource créée.
  ///
  /// [postId] identifie le post cible.
  /// [mediaBytes] contient le payload binaire.
  /// [fileName] est le nom logique envoyé au backend.
  /// [mimeType] permet d'imposer le type MIME.
  /// [onUpdate] reçoit les états de progression/erreur.
  /// Retourne le [Media] créé si succès, sinon lève une exception métier.
  Future<Media?> uploadMedia({required int postId, required Uint8List mediaBytes, required String fileName, String? mimeType, void Function(UploadResult update)? onUpdate}) async {
    final result = await _mediaApiService.uploadMediaFile(postId: postId, mediaBytes: mediaBytes, fileName: fileName, mimeType: mimeType, onUpdate: onUpdate);

    // Stratégie explicite: on propage une exception pour éviter les échecs silencieux.
    // Le message backend est conservé pour diagnostic côté UI.
    if (!result.isSuccess || result.media == null) {
      throw Exception(result.message ?? 'Échec upload média');
    }
    return result.media;
  }

  /// Upload un fichier média et retourne l'état détaillé d'exécution.
  ///
  /// [postId] identifie le post cible.
  /// [mediaBytes] contient le payload binaire.
  /// [fileName] est le nom logique envoyé au backend.
  /// [mimeType] permet d'imposer le type MIME.
  /// [onUpdate] reçoit les états de progression/erreur.
  /// Retourne un [UploadResult] incluant progression, statut et éventuel média.
  Future<UploadResult> uploadMediaWithResult({required int postId, required Uint8List mediaBytes, required String fileName, String? mimeType, void Function(UploadResult update)? onUpdate}) async {
    return _mediaApiService.uploadMediaFile(postId: postId, mediaBytes: mediaBytes, fileName: fileName, mimeType: mimeType, onUpdate: onUpdate);
  }
}
