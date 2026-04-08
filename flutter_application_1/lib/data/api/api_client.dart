import 'dart:convert';
import 'dart:io';
//import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ApiClient {
  

  //final String baseUrl = "https://api-7e6i.onrender.com/api";

  final String baseUrl = "http://localhost:8080/api";
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

  String _buildUrl(String endpoint) {
    return endpoint.startsWith('/') ? '$baseUrl$endpoint' : '$baseUrl/$endpoint';
  }

  Future<dynamic> get(
    String endpoint, {
    bool includeAuthorization = true,
  }) async {
    final url = _buildUrl(endpoint);
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
    final url = _buildUrl(endpoint);
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
    final url = _buildUrl(endpoint);
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
    final url = _buildUrl(endpoint);
    final response = await http.delete(
      Uri.parse(url),
      headers: _buildHeaders(includeAuthorization: includeAuthorization),
    );
    return _handleResponse(response);
  }

  Future<dynamic> uploadMedia(
    int postId,
    File mediaFile, {
    bool includeAuthorization = true,
  }) async {
    final endpoint = '/posts/$postId/media';
    final request = http.MultipartRequest('POST', Uri.parse(_buildUrl(endpoint)));
    final headers = _buildHeaders(includeAuthorization: includeAuthorization);
    headers.remove('Content-Type');
    request.headers.addAll(headers);

    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        mediaFile.path,
        filename: path.basename(mediaFile.path),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
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