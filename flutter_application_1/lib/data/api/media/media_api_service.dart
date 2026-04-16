import 'dart:typed_data';

import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/models/media.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

enum MediaUploadStatus {
  preparing,
  uploading,
  success,
  failure,
}

class UploadResult {
  const UploadResult({
    required this.status,
    required this.progress,
    this.media,
    this.message,
  });

  final MediaUploadStatus status;
  final double progress;
  final Media? media;
  final String? message;

  bool get isSuccess => status == MediaUploadStatus.success;

  factory UploadResult.preparing({String? message}) {
    return UploadResult(
      status: MediaUploadStatus.preparing,
      progress: 0,
      message: message,
    );
  }

  factory UploadResult.uploading({
    required double progress,
    String? message,
  }) {
    return UploadResult(
      status: MediaUploadStatus.uploading,
      progress: progress.clamp(0, 1),
      message: message,
    );
  }

  factory UploadResult.success(Media media, {String? message}) {
    return UploadResult(
      status: MediaUploadStatus.success,
      progress: 1,
      media: media,
      message: message,
    );
  }

  factory UploadResult.failure(String message) {
    return UploadResult(
      status: MediaUploadStatus.failure,
      progress: 0,
      message: message,
    );
  }
}

class CreateMediaRequest {
  const CreateMediaRequest({
    required this.postId,
    required this.url,
  });

  final int postId;
  final String url;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'postId': postId,
      'url': url,
    };
  }
}

class MediaApiService {
  MediaApiService(this._apiClient);

  final IApiClient _apiClient;

  Future<UploadResult> uploadMediaFile({
    required int postId,
    required Uint8List mediaBytes,
    required String fileName,
    String? mimeType,
    bool includeAuthorization = true,
    void Function(UploadResult update)? onUpdate,
  }) async {
    _emit(
      onUpdate,
      UploadResult.preparing(message: 'Préparation du fichier en cours...'),
    );

    try {
      final response = await _apiClient.upload(
        ApiEndpoints.postMedia(postId),
        mediaBytes,
        fileName: fileName,
        mimeType: mimeType,
        includeAuthorization: includeAuthorization,
        onSendProgress: (sent, total) {
          final safeTotal = total <= 0 ? mediaBytes.length : total;
          final progress =
              safeTotal <= 0 ? 0.0 : sent.toDouble() / safeTotal.toDouble();
          _emit(
            onUpdate,
            UploadResult.uploading(
              progress: progress,
              message: 'Envoi vers le service de stockage distant...',
            ),
          );
        },
      );

      if (response is Map<String, dynamic>) {
        final media = Media.fromJson(response);
        final result = UploadResult.success(
          media,
          message: 'Upload terminé avec succès.',
        );
        _emit(onUpdate, result);
        return result;
      }

      final failure = UploadResult.failure('Réponse upload invalide.');
      _emit(onUpdate, failure);
      return failure;
    } catch (error) {
      final failure = UploadResult.failure('Échec upload: $error');
      _emit(onUpdate, failure);
      return failure;
    }
  }

  Future<UploadResult> createMediaFromUrl({
    required int postId,
    required String url,
    bool includeAuthorization = true,
    void Function(UploadResult update)? onUpdate,
  }) async {
    _emit(
      onUpdate,
      UploadResult.preparing(message: 'Création du média depuis URL...'),
    );

    final request = CreateMediaRequest(postId: postId, url: url.trim());

    try {
      final response = await _apiClient.post(
        ApiEndpoints.postMedia(postId),
        request.toJson(),
        includeAuthorization: includeAuthorization,
      );

      if (response is Map<String, dynamic>) {
        final media = Media.fromJson(response);
        final result = UploadResult.success(
          media,
          message: 'Média créé avec succès.',
        );
        _emit(onUpdate, result);
        return result;
      }

      final failure = UploadResult.failure('Réponse média invalide.');
      _emit(onUpdate, failure);
      return failure;
    } catch (error) {
      final failure = UploadResult.failure('Échec création média: $error');
      _emit(onUpdate, failure);
      return failure;
    }
  }

  void _emit(
    void Function(UploadResult update)? onUpdate,
    UploadResult update,
  ) {
    if (onUpdate != null) {
      onUpdate(update);
    }
  }
}
