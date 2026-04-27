import 'dart:typed_data';

import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/models/media.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

/// États du cycle d'upload média.
enum MediaUploadStatus { preparing, uploading, success, failure }

/// Résultat unifié d'une opération média (upload ou création URL).
class UploadResult {
  /// Construit un résultat d'opération média.
  ///
  /// [status] représente l'état courant de l'opération.
  /// [progress] correspond à la progression normalisée entre 0 et 1.
  /// [media] contient la ressource créée en cas de succès.
  /// [message] transporte un message utilisateur/diagnostic.
  const UploadResult({required this.status, required this.progress, this.media, this.message});

  final MediaUploadStatus status;
  final double progress;
  final Media? media;
  final String? message;

  /// Indique si l'opération est terminée avec succès.
  bool get isSuccess => status == MediaUploadStatus.success;

  /// Fabrique un état de préparation initial.
  ///
  /// [message] contient un texte d'état optionnel.
  /// Retourne un [UploadResult] avec progression à `0`.
  factory UploadResult.preparing({String? message}) {
    return UploadResult(status: MediaUploadStatus.preparing, progress: 0, message: message);
  }

  /// Fabrique un état intermédiaire d'upload en cours.
  ///
  /// [progress] est contraint entre `0` et `1`.
  /// [message] contient un texte d'état optionnel.
  /// Retourne un [UploadResult] en statut `uploading`.
  factory UploadResult.uploading({required double progress, String? message}) {
    return UploadResult(status: MediaUploadStatus.uploading, progress: progress.clamp(0, 1), message: message);
  }

  /// Fabrique un état final de succès.
  ///
  /// [media] représente la ressource créée.
  /// [message] contient un texte d'état optionnel.
  /// Retourne un [UploadResult] en statut `success`.
  factory UploadResult.success(Media media, {String? message}) {
    return UploadResult(status: MediaUploadStatus.success, progress: 1, media: media, message: message);
  }

  /// Fabrique un état final d'échec.
  ///
  /// [message] décrit la cause de l'échec.
  /// Retourne un [UploadResult] en statut `failure`.
  factory UploadResult.failure(String message) {
    return UploadResult(status: MediaUploadStatus.failure, progress: 0, message: message);
  }
}

/// Payload de création média à partir d'une URL.
class CreateMediaRequest {
  /// Construit la requête de création média URL.
  ///
  /// [postId] identifie le post cible.
  /// [url] est l'URL du média source.
  const CreateMediaRequest({required this.postId, required this.url});

  final int postId;
  final String url;

  /// Sérialise la requête en JSON.
  ///
  /// Retourne un [Map<String, dynamic>] prêt pour l'API.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      // 'postId': postId,
      'url': url,
    };
  }
}

/// Service API spécialisé pour les opérations média.
///
/// Ce service encapsule la conversion des réponses API en [UploadResult] afin
/// d'unifier la gestion d'état côté UI/repository.
class MediaApiService {
  /// Construit le service média.
  ///
  /// [apiClient] est le client HTTP utilisé pour les appels distants.
  MediaApiService(this._apiClient);

  final IApiClient _apiClient;

  /// Upload un fichier média vers l'API.
  ///
  /// [postId] identifie le post cible.
  /// [mediaBytes] contient le payload binaire.
  /// [fileName] est le nom logique du fichier.
  /// [mimeType] permet d'imposer le type MIME.
  /// [includeAuthorization] active l'injection du token.
  /// [onUpdate] notifie les transitions d'état/progression.
  /// Retourne un [UploadResult] final.
  Future<UploadResult> uploadMediaFile({required int postId, required Uint8List mediaBytes, required String fileName, String? mimeType, bool includeAuthorization = true, void Function(UploadResult update)? onUpdate}) async {
    _emit(onUpdate, UploadResult.preparing(message: 'Préparation du fichier en cours...'));

    try {
      final response = await _apiClient.upload(
        ApiEndpoints.postMedia(postId),
        mediaBytes,
        fileName: fileName,
        mimeType: mimeType,
        includeAuthorization: includeAuthorization,
        onSendProgress: (sent, total) {
          // Sécurise le calcul de progression même si `total` est absent côté transport.
          final safeTotal = total <= 0 ? mediaBytes.length : total;
          final progress = safeTotal <= 0 ? 0.0 : sent.toDouble() / safeTotal.toDouble();
          _emit(onUpdate, UploadResult.uploading(progress: progress, message: 'Envoi vers le service de stockage distant...'));
        },
      );

      if (response is Map<String, dynamic>) {
        final media = Media.fromJson(response);
        final result = UploadResult.success(media, message: 'Upload terminé avec succès.');
        _emit(onUpdate, result);
        return result;
      }

      // Réponse API inattendue: échec fonctionnel explicite.
      final failure = UploadResult.failure('Réponse upload invalide.');
      _emit(onUpdate, failure);
      return failure;
    } catch (error) {
      // Capture uniforme des erreurs transport/API dans un état `failure`.
      final failure = UploadResult.failure('Échec upload: $error');
      _emit(onUpdate, failure);
      return failure;
    }
  }

  /// Crée un média à partir d'une URL distante.
  ///
  /// [postId] identifie le post cible.
  /// [url] est l'URL du média source.
  /// [includeAuthorization] active l'injection du token.
  /// [onUpdate] notifie les transitions d'état.
  /// Retourne un [UploadResult] final.
  Future<UploadResult> createMediaFromUrl({required int postId, required String url, bool includeAuthorization = true, void Function(UploadResult update)? onUpdate}) async {
    _emit(onUpdate, UploadResult.preparing(message: 'Création du média depuis URL...'));

    final request = CreateMediaRequest(postId: postId, url: url.trim());

    try {
      final response = await _apiClient.post(ApiEndpoints.postMedia(postId), request.toJson(), includeAuthorization: includeAuthorization);

      if (response is Map<String, dynamic>) {
        final media = Media.fromJson(response);
        final result = UploadResult.success(media, message: 'Média créé avec succès.');
        _emit(onUpdate, result);
        return result;
      }

      // Réponse API inattendue: échec fonctionnel explicite.
      final failure = UploadResult.failure('Réponse média invalide.');
      _emit(onUpdate, failure);
      return failure;
    } catch (error) {
      // Capture uniforme des erreurs transport/API dans un état `failure`.
      final failure = UploadResult.failure('Échec création média: $error');
      _emit(onUpdate, failure);
      return failure;
    }
  }

  /// Émet une mise à jour d'état vers l'observateur UI/repository.
  ///
  /// [onUpdate] callback cible.
  /// [update] état à transmettre.
  /// Retourne `void`.
  void _emit(void Function(UploadResult update)? onUpdate, UploadResult update) {
    if (onUpdate != null) {
      onUpdate(update);
    }
  }
}
