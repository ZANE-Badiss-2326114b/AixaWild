import 'package:dio/dio.dart';

import 'package:flutter_application_1/data/api/auth/auth_token_manager.dart';
import 'package:flutter_application_1/data/api/core/api_interface.dart';

typedef UnauthorizedHandler = Future<void> Function();
typedef RefreshTokenHandler = Future<String?> Function(String refreshToken);
typedef ForbiddenHandler = Future<void> Function(String message);

/// Implémentation `Dio` du contrat [IApiClient].
///
/// Ce client centralise:
/// - la configuration réseau (timeouts, base URL, headers),
/// - l'injection conditionnelle du token d'accès,
/// - la gestion des erreurs transport/API,
/// - le cycle de refresh token via l'intercepteur.
class DioApiClient implements IApiClient {
  /// Crée un client API Dio.
  ///
  /// [dio] permet d'injecter une instance custom pour les tests.
  /// [authTokenManager] fournit l'accès aux tokens persistés.
  /// [onUnauthorized] est appelé après une séquence 401 non récupérable.
  /// [onRefreshToken] tente de renvoyer un nouveau token d'accès.
  /// [onForbidden] est appelé pour les réponses 403.
  DioApiClient({Dio? dio, AuthTokenManager? authTokenManager, this.onUnauthorized, this.onRefreshToken, this.onForbidden}) : _dio = dio ?? Dio(BaseOptions(baseUrl: _apiBaseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30), sendTimeout: const Duration(seconds: 30), responseType: ResponseType.json, headers: const <String, dynamic>{'Accept': 'application/json', 'User-Agent': 'Flutter-Aixawild'})), _authTokenManager = authTokenManager ?? AuthTokenManager.instance {
    _dio.interceptors.add(_AuthInterceptor(dio: _dio, authTokenManager: _authTokenManager, onUnauthorized: onUnauthorized, onRefreshToken: onRefreshToken, onForbidden: onForbidden));
  }
  static const String _apiBaseUrl = 'https://api-7e6i.onrender.com/api';
  //static const String _apiBaseUrl = 'http://localhost:8080/api';

  final Dio _dio;
  final AuthTokenManager _authTokenManager;
  final UnauthorizedHandler? onUnauthorized;
  final RefreshTokenHandler? onRefreshToken;
  final ForbiddenHandler? onForbidden;

  @override
  /// Exécute une requête GET et retourne `response.data`.
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        options: _buildOptions(headers: headers, includeAuthorization: includeAuthorization),
      );
      return response.data;
    } on DioException catch (error) {
      // Uniformise toutes les erreurs Dio en exception applicative lisible.
      throw _mapException(error);
    }
  }

  @override
  /// Exécute une requête POST et retourne `response.data`.
  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: data,
        options: _buildOptions(headers: headers, includeAuthorization: includeAuthorization),
      );

      return response.data;
    } on DioException catch (error) {
      // Uniformise toutes les erreurs Dio en exception applicative lisible.
      throw _mapException(error);
    }
  }

  @override
  /// Exécute une requête PUT et retourne `response.data`.
  Future<dynamic> put(String endpoint, dynamic data, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    try {
      final response = await _dio.put<dynamic>(
        endpoint,
        data: data,
        options: _buildOptions(headers: headers, includeAuthorization: includeAuthorization),
      );
      return response.data;
    } on DioException catch (error) {
      // Uniformise toutes les erreurs Dio en exception applicative lisible.
      throw _mapException(error);
    }
  }

  @override
  /// Exécute une requête DELETE et retourne `response.data`.
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    try {
      final response = await _dio.delete<dynamic>(
        endpoint,
        options: _buildOptions(headers: headers, includeAuthorization: includeAuthorization),
      );
      return response.data;
    } on DioException catch (error) {
      // Uniformise toutes les erreurs Dio en exception applicative lisible.
      throw _mapException(error);
    }
  }

  @override
  /// Envoie un fichier en multipart/form-data.
  ///
  /// [endpoint] cible l'URL relative d'upload.
  /// [bytes] contient le binaire à transmettre.
  /// [fileName] est utilisé pour la partie multipart.
  /// [mimeType] permet d'imposer un type MIME; sinon il est inféré.
  /// [headers] ajoute des en-têtes spécifiques.
  /// [includeAuthorization] active l'injection automatique du Bearer token.
  /// [onSendProgress] reçoit l'avancement `(sent, total)`.
  /// Retourne `response.data`.
  Future<dynamic> upload(String endpoint, List<int> bytes, {required String fileName, String? mimeType, Map<String, String>? headers, bool includeAuthorization = true, void Function(int sent, int total)? onSendProgress}) async {
    final contentType = _resolveMimeType(fileName, mimeType);
    final formData = FormData.fromMap(<String, dynamic>{'file': MultipartFile.fromBytes(bytes, filename: fileName, contentType: DioMediaType.parse(contentType))});

    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        options: _buildOptions(headers: headers, includeAuthorization: includeAuthorization, contentType: Headers.multipartFormDataContentType),
      );
      return response.data;
    } on DioException catch (error) {
      // Uniformise toutes les erreurs Dio en exception applicative lisible.
      throw _mapException(error);
    }
  }

  /// Construit les options de requête Dio avec indicateur d'auth.
  ///
  /// [headers] ajoute des en-têtes personnalisés.
  /// [includeAuthorization] contrôle l'injection automatique du token.
  /// [contentType] surcharge le content-type de la requête.
  /// Retourne une instance [Options] utilisée par Dio.
  Options _buildOptions({Map<String, String>? headers, required bool includeAuthorization, String? contentType}) {
    return Options(headers: headers, contentType: contentType, extra: <String, dynamic>{_AuthInterceptor.requiresAuthKey: includeAuthorization});
  }

  /// Transforme une [DioException] en exception applicative lisible.
  ///
  /// [error] est l'erreur brute transport/API renvoyée par Dio.
  /// Retourne une [Exception] avec message contextualisé.
  Exception _mapException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;

    if (statusCode == null) {
      String networkMessage;
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          networkMessage = 'délai de connexion dépassé';
          break;
        case DioExceptionType.sendTimeout:
          networkMessage = 'délai d\'envoi dépassé';
          break;
        case DioExceptionType.receiveTimeout:
          networkMessage = 'délai de réponse dépassé';
          break;
        case DioExceptionType.connectionError:
          networkMessage = 'connexion impossible';
          break;
        case DioExceptionType.badCertificate:
          networkMessage = 'certificat SSL invalide';
          break;
        case DioExceptionType.cancel:
          networkMessage = 'requête annulée';
          break;
        case DioExceptionType.unknown:
        case DioExceptionType.badResponse:
          networkMessage = 'erreur réseau inconnue';
          break;
      }

      // Cas transport: pas de code HTTP disponible.
      return Exception('Erreur API (réseau): $networkMessage (${error.message ?? 'sans détail'})');
    }

    // Cas réponse HTTP: on remonte le status et le body renvoyé par l'API.
    return Exception(
      'Erreur API ($statusCode): '
      '${responseData ?? error.message ?? 'requête impossible'}',
    );
  }

  /// Détermine un MIME type à partir du nom de fichier si absent.
  ///
  /// [fileName] est utilisé pour l'inférence par extension.
  /// [mimeType] est prioritaire si renseigné et valide.
  /// Retourne le type MIME final envoyé en multipart.
  String _resolveMimeType(String fileName, String? mimeType) {
    final normalized = mimeType?.trim().toLowerCase();
    if (normalized != null && normalized.isNotEmpty && normalized.contains('/')) {
      return normalized;
    }

    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) return 'image/jpeg';
    if (lowerName.endsWith('.gif')) return 'image/gif';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.bmp')) return 'image/bmp';
    if (lowerName.endsWith('.svg')) return 'image/svg+xml';
    if (lowerName.endsWith('.mp4')) return 'video/mp4';
    if (lowerName.endsWith('.mov')) return 'video/quicktime';
    if (lowerName.endsWith('.webm')) return 'video/webm';
    if (lowerName.endsWith('.m4v')) return 'video/x-m4v';
    if (lowerName.endsWith('.avi')) return 'video/x-msvideo';
    if (lowerName.endsWith('.mkv')) return 'video/x-matroska';
    return 'application/octet-stream';
  }
}

/// Intercepteur Dio responsable de l'authentification transparente.
///
/// Il gère l'injection du token, la persistance d'un nouveau token en réponse,
/// et la stratégie de retry lors d'un 401 via refresh token.
class _AuthInterceptor extends Interceptor {
  /// Crée l'intercepteur d'authentification.
  ///
  /// [dio] est requis pour relancer la requête après refresh.
  /// [authTokenManager] fournit lecture/écriture des tokens.
  /// [onUnauthorized] est appelé après échec de refresh.
  /// [onRefreshToken] tente de produire un nouveau token d'accès.
  /// [onForbidden] notifie l'application sur 403.
  _AuthInterceptor({required Dio dio, required AuthTokenManager authTokenManager, required this.onUnauthorized, required this.onRefreshToken, required this.onForbidden}) : _dio = dio, _authTokenManager = authTokenManager;

  static const String requiresAuthKey = 'requiresAuthorization';
  static const String retried401Key = 'retriedAfterUnauthorized';

  final Dio _dio;
  final AuthTokenManager _authTokenManager;
  final UnauthorizedHandler? onUnauthorized;
  final RefreshTokenHandler? onRefreshToken;
  final ForbiddenHandler? onForbidden;

  @override
  /// Injecte le header Authorization si nécessaire.
  ///
  /// [options] contient les métadonnées de requête et l'extra `requiresAuthorization`.
  /// [handler] poursuit la chaîne d'intercepteurs.
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final requiresAuthorization = options.extra[requiresAuthKey] != false;

    if (requiresAuthorization && !options.headers.containsKey('Authorization')) {
      // Ajout automatique du bearer token pour les endpoints protégés.
      final accessToken = await _authTokenManager.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  /// Persiste un token retourné dans les headers de réponse.
  ///
  /// [response] est inspectée pour récupérer `Authorization: Bearer ...`.
  /// [handler] poursuit la chaîne d'intercepteurs.
  Future<void> onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    final authorizationHeader = response.headers.value('authorization') ?? response.headers.value('Authorization');

    if (authorizationHeader != null && authorizationHeader.toLowerCase().startsWith('bearer ')) {
      final newToken = authorizationHeader.substring('Bearer '.length).trim();
      if (newToken.isNotEmpty) {
        await _authTokenManager.saveAccessToken(newToken);
      }
    }

    handler.next(response);
  }

  @override
  /// Gère 403 et stratégie de refresh/retry sur 401.
  ///
  /// [error] est l'erreur interceptée par Dio.
  /// [handler] permet de résoudre/rejeter l'erreur après traitement.
  Future<void> onError(DioException error, ErrorInterceptorHandler handler) async {
    final statusCode = error.response?.statusCode;
    final requestOptions = error.requestOptions;
    final requiresAuthorization = requestOptions.extra[requiresAuthKey] != false;
    const forbiddenMessage = 'Accès refusé : Vous n\'avez pas les droits nécessaires';

    if (statusCode == 403) {
      // Notification explicite côté UI lorsqu'une action est interdite.
      if (onForbidden != null) {
        await onForbidden!(forbiddenMessage);
      }
    }

    if (statusCode == 401 && requiresAuthorization) {
      // Évite les boucles infinies de refresh sur une même requête.
      final alreadyRetried = requestOptions.extra[retried401Key] == true;

      if (!alreadyRetried && onRefreshToken != null) {
        // Tente une récupération de session à partir du refresh token.
        final refreshToken = await _authTokenManager.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedAccessToken = await onRefreshToken!(refreshToken);
          if (refreshedAccessToken != null && refreshedAccessToken.isNotEmpty) {
            await _authTokenManager.saveAccessToken(refreshedAccessToken);

            requestOptions.headers['Authorization'] = 'Bearer $refreshedAccessToken';
            requestOptions.extra[retried401Key] = true;

            try {
              // Replay transparent de la requête initiale après refresh réussi.
              final retryResponse = await _dio.fetch<dynamic>(requestOptions);
              handler.resolve(retryResponse);
              return;
            } on DioException catch (retryError) {
              // Si le retry échoue, on invalide la session et on remonte l'erreur.
              await _authTokenManager.clearTokens();
              if (onUnauthorized != null) {
                await onUnauthorized!();
              }
              handler.next(retryError);
              return;
            }
          }
        }
      }

      // Aucun refresh possible: la session est invalidée côté client.
      await _authTokenManager.clearTokens();
      if (onUnauthorized != null) {
        await onUnauthorized!();
      }
    }

    handler.next(error);
  }
}
