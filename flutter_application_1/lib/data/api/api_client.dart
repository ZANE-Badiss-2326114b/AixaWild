import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl = "https://api-7e6i.onrender.com/api";
  
  //final String baseUrl = "http://172.17.0.1:8080/api";

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
      } else {
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