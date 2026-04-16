abstract class IApiClient {
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, bool includeAuthorization = true});

  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers, bool includeAuthorization = true});

  Future<dynamic> put(String endpoint, dynamic data, {Map<String, String>? headers, bool includeAuthorization = true});

  Future<dynamic> delete(String endpoint, {Map<String, String>? headers, bool includeAuthorization = true});

  Future<dynamic> upload(String endpoint, List<int> bytes, {required String fileName, String? mimeType, Map<String, String>? headers, bool includeAuthorization = true, void Function(int sent, int total)? onSendProgress});
}
