import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl = "https://api-7e6i.onrender.com/api";
  
  //final String baseUrl = "http://172.17.0.1:8080/api";
  
  // "MTox" est le Base64 de "1:1"
  final String _auth = 'Basic MTox';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': _auth,
    'User-Agent': 'Flutter-Aixawild',
  };

  Future<dynamic> get(String endpoint) async {
    final url = endpoint.startsWith('/') ? '$baseUrl$endpoint' : '$baseUrl/$endpoint';
    final response = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final url = endpoint.startsWith('/') ? '$baseUrl$endpoint' : '$baseUrl/$endpoint';
    final response = await http.post(
      Uri.parse(url), 
      headers: _headers, 
      body: jsonEncode(data)
    );
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } else {
      throw Exception('Erreur API (${response.statusCode}): ${response.body}');
    }
  }
}