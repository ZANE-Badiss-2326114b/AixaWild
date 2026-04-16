import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'package:flutter_application_1/data/api/auth/auth_token_manager.dart';
import 'package:flutter_application_1/data/api/core/api_interface.dart';

class ApiClient implements IApiClient {
  static const String _defaultApiBaseUrl = 'http://localhost:8080/api';
  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultApiBaseUrl,
  );

  ApiClient({
    AuthTokenManager? authTokenManager,
    this.baseUrl = _configuredApiBaseUrl,
  }) : _authTokenManager = authTokenManager ?? AuthTokenManager.instance;

  final String baseUrl;
  final AuthTokenManager _authTokenManager;

  static String buildBasicAuthorizationHeader(String email, String password) {
    final credentials = '${email.trim()}:$password';
    return 'Basic ${base64Encode(utf8.encode(credentials))}';
  }

  static Map<String, String> mediaRequestHeaders() {
    final token = AuthTokenManager.instance.cachedToken;
    if (token == null || token.isEmpty) {
      return const <String, String>{};
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _buildHeaders({
    bool includeAuthorization = true,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Flutter-Aixawild',
    };

    return _injectAuthorizationIfNeeded(
      headers,
      includeAuthorization: includeAuthorization,
      extraHeaders: extraHeaders,
    );
  }

  Future<Map<String, String>> _injectAuthorizationIfNeeded(
    Map<String, String> baseHeaders, {
    required bool includeAuthorization,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = <String, String>{...baseHeaders};
    if (extraHeaders != null && extraHeaders.isNotEmpty) {
      headers.addAll(extraHeaders);
    }

    if (!includeAuthorization || headers.containsKey('Authorization')) {
      return headers;
    }

    final token = await _authTokenManager.getToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<void> _captureJwtFromHeaders(Map<String, String> headers) async {
    final authorization =
        headers['authorization'] ?? headers['Authorization'] ?? '';
    if (!authorization.toLowerCase().startsWith('bearer ')) {
      return;
    }

    final token = authorization.substring('Bearer '.length).trim();
    if (token.isNotEmpty) {
      await _authTokenManager.saveToken(token);
    }
  }

  Future<void> clearAuthToken() async {
    await _authTokenManager.clearToken();
  }

  Future<void> saveAuthToken(String token) async {
    await _authTokenManager.saveToken(token);
  }

  String? getCachedAuthToken() {
    return _authTokenManager.cachedToken;
  }

  String _buildUrl(String endpoint) {
    return endpoint.startsWith('/') ? '$baseUrl$endpoint' : '$baseUrl/$endpoint';
  }

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? headers,
    bool includeAuthorization = true,
  }) async {
    final url = _buildUrl(endpoint);
    final response = await http.get(
      Uri.parse(url),
      headers: await _buildHeaders(
        includeAuthorization: includeAuthorization,
        extraHeaders: headers,
      ),
    );
    return _handleResponse(response);
  }

  @override
  Future<dynamic> post(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
    bool includeAuthorization = true,
  }) async {
    final url = _buildUrl(endpoint);
    final response = await http.post(
      Uri.parse(url),
      headers: await _buildHeaders(
        includeAuthorization: includeAuthorization,
        extraHeaders: headers,
      ),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  @override
  Future<dynamic> put(
    String endpoint,
    dynamic data, {
    Map<String, String>? headers,
    bool includeAuthorization = true,
  }) async {
    final url = _buildUrl(endpoint);
    final response = await http.put(
      Uri.parse(url),
      headers: await _buildHeaders(
        includeAuthorization: includeAuthorization,
        extraHeaders: headers,
      ),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  @override
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
    bool includeAuthorization = true,
  }) async {
    final url = _buildUrl(endpoint);
    final response = await http.delete(
      Uri.parse(url),
      headers: await _buildHeaders(
        includeAuthorization: includeAuthorization,
        extraHeaders: headers,
      ),
    );
    return _handleResponse(response);
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
    onSendProgress?.call(0, bytes.length);
    final request = http.MultipartRequest('POST', Uri.parse(_buildUrl(endpoint)));
    final requestHeaders = await _buildHeaders(
      includeAuthorization: includeAuthorization,
      extraHeaders: headers,
    );
    requestHeaders.remove('Content-Type');
    request.headers.addAll(requestHeaders);

    final resolvedMimeType = _resolveMimeType(fileName, mimeType);

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(resolvedMimeType),
      ),
    );

    final streamedResponse = await request.send();
    onSendProgress?.call(bytes.length, bytes.length);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<dynamic> uploadMedia(
    int postId,
    Uint8List mediaBytes, {
    required String fileName,
    String? mimeType,
    bool includeAuthorization = true,
  }) async {
    return upload(
      '/posts/$postId/media',
      mediaBytes,
      fileName: fileName,
      mimeType: mimeType,
      includeAuthorization: includeAuthorization,
    );
  }

  Future<dynamic> _handleResponse(http.Response response) async {
    await _captureJwtFromHeaders(response.headers);

    dynamic result;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        result = jsonDecode(response.body);
      } else {
        result = null;
      }
    }

    else {
      throw Exception('Erreur API (${response.statusCode}): ${response.body}');
    }

    return result;
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