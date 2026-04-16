import 'package:dio/dio.dart';

import 'package:flutter_application_1/data/api/auth/auth_token_manager.dart';
import 'package:flutter_application_1/data/api/core/api_interface.dart';

typedef UnauthorizedHandler = Future<void> Function();
typedef RefreshTokenHandler = Future<String?> Function(String refreshToken);

class DioApiClient implements IApiClient {
  DioApiClient({
    Dio? dio,
    AuthTokenManager? authTokenManager,
    this.baseUrl = _configuredApiBaseUrl,
    this.onUnauthorized,
    this.onRefreshToken,
  })  : _dio =
            dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
                responseType: ResponseType.json,
                headers: const <String, dynamic>{
                  'Accept': 'application/json',
                  'User-Agent': 'Flutter-Aixawild',
                },
              ),
            ),
        _authTokenManager = authTokenManager ?? AuthTokenManager.instance {
    _dio.interceptors.add(
      _AuthInterceptor(
        dio: _dio,
        authTokenManager: _authTokenManager,
        onUnauthorized: onUnauthorized,
        onRefreshToken: onRefreshToken,
      ),
    );
  }

  static const String _defaultApiBaseUrl = 'http://localhost:8080/api';
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  final Dio _dio;
  final String baseUrl;
  final AuthTokenManager _authTokenManager;
  final UnauthorizedHandler? onUnauthorized;
  final RefreshTokenHandler? onRefreshToken;

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    bool includeAuthorization = true,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        options: _buildOptions(
          headers: headers,
          includeAuthorization: includeAuthorization,
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  @override
  Future<dynamic> post(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
    bool includeAuthorization = true,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: data,
        options: _buildOptions(
          headers: headers,
          includeAuthorization: includeAuthorization,
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  @override
  Future<dynamic> put(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
    bool includeAuthorization = true,
  }) async {
    try {
      final response = await _dio.put<dynamic>(
        endpoint,
        data: data,
        options: _buildOptions(
          headers: headers,
          includeAuthorization: includeAuthorization,
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool includeAuthorization = true,
  }) async {
    try {
      final response = await _dio.delete<dynamic>(
        endpoint,
        options: _buildOptions(
          headers: headers,
          includeAuthorization: includeAuthorization,
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  @override
  Future<dynamic> upload(
    String endpoint,
    List<int> bytes, {
    required String fileName,
    String? mimeType,
    Map<String, String>? headers,
    bool includeAuthorization = true,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    final contentType = _resolveMimeType(fileName, mimeType);
    final formData = FormData.fromMap(
      <String, dynamic>{
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType.parse(contentType),
        ),
      },
    );

    try {
      final response = await _dio.post<dynamic>(
        endpoint,
        data: formData,
        onSendProgress: onSendProgress,
        options: _buildOptions(
          headers: headers,
          includeAuthorization: includeAuthorization,
          contentType: Headers.multipartFormDataContentType,
        ),
      );
      return response.data;
    } on DioException catch (error) {
      throw _mapException(error);
    }
  }

  Future<void> clearAuthTokens() async {
    await _authTokenManager.clearTokens();
  }

  Options _buildOptions({
    Map<String, String>? headers,
    required bool includeAuthorization,
    String? contentType,
  }) {
    return Options(
      headers: headers,
      contentType: contentType,
      extra: <String, dynamic>{
        _AuthInterceptor.requiresAuthKey: includeAuthorization,
      },
    );
  }

  Exception _mapException(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    return Exception(
      'Erreur API (${statusCode ?? 'inconnue'}): '
      '${responseData ?? error.message ?? 'requête impossible'}',
    );
  }

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

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({
    required Dio dio,
    required AuthTokenManager authTokenManager,
    required this.onUnauthorized,
    required this.onRefreshToken,
  })  : _dio = dio,
        _authTokenManager = authTokenManager;

  static const String requiresAuthKey = 'requiresAuthorization';
  static const String retried401Key = 'retriedAfterUnauthorized';

  final Dio _dio;
  final AuthTokenManager _authTokenManager;
  final UnauthorizedHandler? onUnauthorized;
  final RefreshTokenHandler? onRefreshToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final requiresAuthorization =
        options.extra[requiresAuthKey] != false;

    if (requiresAuthorization && !options.headers.containsKey('Authorization')) {
      final accessToken = await _authTokenManager.getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    final authorizationHeader =
        response.headers.value('authorization') ??
            response.headers.value('Authorization');

    if (authorizationHeader != null &&
        authorizationHeader.toLowerCase().startsWith('bearer ')) {
      final newToken = authorizationHeader.substring('Bearer '.length).trim();
      if (newToken.isNotEmpty) {
        await _authTokenManager.saveAccessToken(newToken);
      }
    }

    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = error.response?.statusCode;
    final requestOptions = error.requestOptions;
    final requiresAuthorization = requestOptions.extra[requiresAuthKey] != false;

    if (statusCode == 401 && requiresAuthorization) {
      final alreadyRetried = requestOptions.extra[retried401Key] == true;

      if (!alreadyRetried && onRefreshToken != null) {
        final refreshToken = await _authTokenManager.getRefreshToken();
        if (refreshToken != null && refreshToken.isNotEmpty) {
          final refreshedAccessToken = await onRefreshToken!(refreshToken);
          if (refreshedAccessToken != null && refreshedAccessToken.isNotEmpty) {
            await _authTokenManager.saveAccessToken(refreshedAccessToken);

            requestOptions.headers['Authorization'] =
                'Bearer $refreshedAccessToken';
            requestOptions.extra[retried401Key] = true;

            try {
              final retryResponse = await _dio.fetch<dynamic>(requestOptions);
              handler.resolve(retryResponse);
              return;
            } on DioException catch (retryError) {
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

      await _authTokenManager.clearTokens();
      if (onUnauthorized != null) {
        await onUnauthorized!();
      }
    }

    handler.next(error);
  }
}
