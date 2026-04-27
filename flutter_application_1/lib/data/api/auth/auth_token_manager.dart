import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Future<void> _writeToStorage({required String key, required String value}) async {
  //   try {
  //     await _storage.write(key: key, value: value);
  //   } on PlatformException {}
  // }
  

  Future<void> _writeToStorage({required String key, required String value}) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      print("Erreur Secure Storage (Écriture), fallback sur SharedPreferences : $e");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  Future<String?> _readFromStorage(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      print("Erreur Secure Storage (Lecture), fallback sur SharedPreferences : $e");
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  Future<void> _deleteFromStorage(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException catch (e) {
      print("Erreur Secure Storage (Suppression), fallback sur SharedPreferences : $e");
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  Future<void> saveAccessToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      await clearAccessToken();
    } else {
      _cachedAccessToken = normalizedToken;
      await _writeToStorage(key: _accessTokenStorageKey, value: normalizedToken);
    }
  }

  Future<void> saveRefreshToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      await clearRefreshToken();
    } else {
      _cachedRefreshToken = normalizedToken;
      await _writeToStorage(key: _refreshTokenStorageKey, value: normalizedToken);
    }
  }

  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    String? accessToken;

    if (_cachedAccessToken != null && _cachedAccessToken!.isNotEmpty) {
      accessToken = _cachedAccessToken;
    } else {
      final token = await _readFromStorage(_accessTokenStorageKey);
      final normalizedToken = token?.trim();

      if (normalizedToken == null || normalizedToken.isEmpty) {
        _cachedAccessToken = null;
        accessToken = null;
      } else {
        _cachedAccessToken = normalizedToken;
        accessToken = _cachedAccessToken;
      }
    }

    return accessToken;
  }

  Future<String?> getRefreshToken() async {
    String? refreshToken;

    if (_cachedRefreshToken != null && _cachedRefreshToken!.isNotEmpty) {
      refreshToken = _cachedRefreshToken;
    } else {
      final token = await _readFromStorage(_refreshTokenStorageKey);
      final normalizedToken = token?.trim();

      if (normalizedToken == null || normalizedToken.isEmpty) {
        _cachedRefreshToken = null;
        refreshToken = null;
      } else {
        _cachedRefreshToken = normalizedToken;
        refreshToken = _cachedRefreshToken;
      }
    }

    return refreshToken;
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
