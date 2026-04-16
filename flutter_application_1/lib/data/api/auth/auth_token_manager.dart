import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class AuthTokenManager {
  AuthTokenManager._({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  static final AuthTokenManager instance = AuthTokenManager._();

  static const String _accessTokenStorageKey = 'access_token';
  static const String _refreshTokenStorageKey = 'refresh_token';

  final FlutterSecureStorage _storage;
  String? _cachedAccessToken;
  String? _cachedRefreshToken;

  String? get cachedAccessToken => _cachedAccessToken;
  String? get cachedRefreshToken => _cachedRefreshToken;
  String? get cachedToken => _cachedAccessToken;

  Future<void> _writeToStorage({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException {
      return;
    }
  }

  Future<String?> _readFromStorage(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException {
      return null;
    }
  }

  Future<void> _deleteFromStorage(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException {
      return;
    }
  }

  Future<void> saveAccessToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      await clearAccessToken();
      return;
    }

    _cachedAccessToken = normalizedToken;
    await _writeToStorage(key: _accessTokenStorageKey, value: normalizedToken);
  }

  Future<void> saveRefreshToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      await clearRefreshToken();
      return;
    }

    _cachedRefreshToken = normalizedToken;
    await _writeToStorage(key: _refreshTokenStorageKey, value: normalizedToken);
  }

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      return _cachedAccessToken;
    }

    final token = await _readFromStorage(_accessTokenStorageKey);
    final normalizedToken = token?.trim();
    if (normalizedToken == null || normalizedToken.isEmpty) {
      _cachedAccessToken = null;
      return null;
    }

    _cachedAccessToken = normalizedToken;
    return _cachedAccessToken;
  }

  Future<String?> getRefreshToken() async {
    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      return _cachedRefreshToken;
    }

    final token = await _readFromStorage(_refreshTokenStorageKey);
    final normalizedToken = token?.trim();
    if (normalizedToken == null || normalizedToken.isEmpty) {
      _cachedRefreshToken = null;
      return null;
    }

    _cachedRefreshToken = normalizedToken;
    return _cachedRefreshToken;
  }

  Future<void> clearAccessToken() async {
    _cachedAccessToken = null;
    await _deleteFromStorage(_accessTokenStorageKey);
  }

  Future<void> clearRefreshToken() async {
    _cachedRefreshToken = null;
    await _deleteFromStorage(_refreshTokenStorageKey);
  }

  Future<void> clearTokens() async {
    await clearAccessToken();
    await clearRefreshToken();
  }

  Future<void> clearOnLogout() async {
    await clearTokens();
  }

  Future<Map<String, String?>> getTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return <String, String?>{'accessToken': accessToken, 'refreshToken': refreshToken};
  }

  Future<void> saveToken(String token) async {
    await saveAccessToken(token);
  }

  Future<String?> getToken() async {
    return getAccessToken();
  }

  Future<void> clearToken() async {
    await clearAccessToken();
  }
}
