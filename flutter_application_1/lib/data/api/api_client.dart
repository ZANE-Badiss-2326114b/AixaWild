import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  //final String baseUrl = "https://api-7e6i.onrender.com/api";

  static String get _defaultBaseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) {
      return _normalizeBaseUrl(override);
    }

    if (kIsWeb) {
      return 'http://localhost:8080/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8080/api';
    }

    return 'http://localhost:8080/api';
  }

  final String baseUrl;

  ApiClient({String? baseUrl})
      : baseUrl = _normalizeBaseUrl(baseUrl ?? _defaultBaseUrl);

  static String _normalizeBaseUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      return trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static String? _sessionEmail;
  static String? _sessionPassword;

  static void setCredentials({
    required String email,
    required String password,
  }) {
    _sessionEmail = email.trim();
    _sessionPassword = password;
  }

  static void clearCredentials() {
    _sessionEmail = null;
    _sessionPassword = null;
  }

  String? get _auth {
    final email = _sessionEmail;
    final password = _sessionPassword;
    String? auth;

    if (email == null || email.isEmpty || password == null) {
      auth = null;
    } else {
      final credentials = '$email:$password';
      auth = 'Basic ${base64Encode(utf8.encode(credentials))}';
    }

    return auth;
  }

  Map<String, String> _buildHeaders({
    bool includeAuthorization = true,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'Flutter-Aixawild',
    };

    if (includeAuthorization) {
      final auth = _auth;
      if (auth != null) {
        headers['Authorization'] = auth;
      }
    }

    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    bool includeAuthorization = true,
  }) async {
    final url = endpoint.startsWith('/') ? '$baseUrl$endpoint' : '$baseUrl/$endpoint';
    final response = await http.get(
      Uri.parse(url),
      headers: _buildHeaders(includeAuthorization: includeAuthorization),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuthorization = true,
  }) async {
    final url = endpoint.startsWith('/') ? '$baseUrl$endpoint' : '$baseUrl/$endpoint';
    final response = await http.post(
      Uri.parse(url), 
      headers: _buildHeaders(includeAuthorization: includeAuthorization), 
      body: jsonEncode(data)
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> data, {
    bool includeAuthorization = true,
  }) async {
    final url = endpoint.startsWith('/') ? '$baseUrl$endpoint' : '$baseUrl/$endpoint';
    final response = await http.put(
      Uri.parse(url),
      headers: _buildHeaders(includeAuthorization: includeAuthorization),
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String endpoint, {
    bool includeAuthorization = true,
  }) async {
    final url = endpoint.startsWith('/') ? '$baseUrl$endpoint' : '$baseUrl/$endpoint';
    final response = await http.delete(
      Uri.parse(url),
      headers: _buildHeaders(includeAuthorization: includeAuthorization),
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic result;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        result = jsonDecode(response.body);
      } else {
        result = null;
      }
    } else {
      throw Exception('Erreur API (${response.statusCode}): ${response.body}');
    }

    return result;
  }
}