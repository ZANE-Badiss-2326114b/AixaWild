import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gestionnaire central des tokens d'authentification.
///
/// Rôle architectural:
/// - source unique de vérité pour access/refresh token dans la couche Data,
/// - cache mémoire pour réduire les lectures I/O,
/// - persistance multi-plateforme avec stratégie de fallback.
///
/// Fallback documenté:
/// 1. priorise `flutter_secure_storage` (stockage chiffré),
/// 2. en cas de `PlatformException` (Linux/Windows selon configuration),
///    bascule automatiquement vers `SharedPreferences`.
class AuthTokenManager {
  /// Construit le gestionnaire avec un backend de stockage sécurisé injectable.
  ///
  /// [storage] permet l'injection d'un backend custom (tests).
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

  /// Écrit une valeur dans le stockage persistant avec fallback non bloquant.
  ///
  /// [key] est la clé de persistance.
  /// [value] est la valeur à sauvegarder.
  /// Retourne `Future<void>` une fois la persistance terminée.
  Future<void> _writeToStorage({required String key, required String value}) async {
    try {
      // Chemin nominal: stockage chiffré.
      await _storage.write(key: key, value: value);
    } on PlatformException {
      // Fallback Linux/Windows si secure storage indisponible.
      // Le token reste persistant mais sans chiffrement matériel.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    }
  }

  /// Lit une valeur depuis le stockage persistant avec fallback.
  ///
  /// [key] est la clé de persistance.
  /// Retourne la valeur trouvée, sinon `null`.
  Future<String?> _readFromStorage(String key) async {
    try {
      // Chemin nominal: stockage chiffré.
      return await _storage.read(key: key);
    } on PlatformException {
      // Fallback Linux/Windows si secure storage indisponible.
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
  }

  /// Supprime une valeur du stockage persistant avec fallback.
  ///
  /// [key] est la clé de persistance.
  /// Retourne `Future<void>` une fois la suppression terminée.
  Future<void> _deleteFromStorage(String key) async {
    try {
      // Chemin nominal: stockage chiffré.
      await _storage.delete(key: key);
    } on PlatformException {
      // Fallback Linux/Windows si secure storage indisponible.
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    }
  }

  /// Sauvegarde le token d'accès.
  ///
  /// [token] est normalisé (`trim`) avant persistance.
  /// Si vide, supprime le token existant.
  /// Retourne `Future<void>`.
  Future<void> saveAccessToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      await clearAccessToken();
    } else {
      _cachedAccessToken = normalizedToken;
      await _writeToStorage(key: _accessTokenStorageKey, value: normalizedToken);
    }
  }

  /// Sauvegarde le token de rafraîchissement.
  ///
  /// [token] est normalisé (`trim`) avant persistance.
  /// Si vide, supprime le refresh token existant.
  /// Retourne `Future<void>`.
  Future<void> saveRefreshToken(String token) async {
    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      await clearRefreshToken();
    } else {
      _cachedRefreshToken = normalizedToken;
      await _writeToStorage(key: _refreshTokenStorageKey, value: normalizedToken);
    }
  }

  /// Sauvegarde les deux tokens de session.
  ///
  /// [accessToken] est obligatoire.
  /// [refreshToken] est optionnel.
  /// Retourne `Future<void>`.
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    await saveAccessToken(accessToken);
    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }
  }

  /// Retourne le token d'accès courant.
  ///
  /// Priorité de lecture:
  /// 1. cache mémoire,
  /// 2. stockage persistant.
  /// Retourne `null` si absent ou invalide.
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

  /// Retourne le refresh token courant.
  ///
  /// Priorité de lecture:
  /// 1. cache mémoire,
  /// 2. stockage persistant.
  /// Retourne `null` si absent ou invalide.
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

  /// Supprime le token d'accès du cache et du stockage.
  ///
  /// Retourne `Future<void>`.
  Future<void> clearAccessToken() async {
    _cachedAccessToken = null;
    await _deleteFromStorage(_accessTokenStorageKey);
  }

  /// Supprime le refresh token du cache et du stockage.
  ///
  /// Retourne `Future<void>`.
  Future<void> clearRefreshToken() async {
    _cachedRefreshToken = null;
    await _deleteFromStorage(_refreshTokenStorageKey);
  }

  /// Supprime tous les tokens de session.
  ///
  /// Retourne `Future<void>`.
  Future<void> clearTokens() async {
    await clearAccessToken();
    await clearRefreshToken();
  }

  /// Alias métier appelé au logout.
  ///
  /// Retourne `Future<void>`.
  Future<void> clearOnLogout() async {
    await clearTokens();
  }

  /// Retourne les tokens sous forme de map.
  ///
  /// Retourne une map avec clés `accessToken` et `refreshToken`.
  Future<Map<String, String?>> getTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return <String, String?>{'accessToken': accessToken, 'refreshToken': refreshToken};
  }

  /// Alias legacy pour sauvegarder un token d'accès.
  ///
  /// [token] représente l'access token.
  /// Retourne `Future<void>`.
  Future<void> saveToken(String token) async {
    await saveAccessToken(token);
  }

  /// Alias legacy pour lire un token d'accès.
  ///
  /// Retourne le token d'accès courant ou `null`.
  Future<String?> getToken() async {
    return getAccessToken();
  }

  /// Alias legacy pour supprimer un token d'accès.
  ///
  /// Retourne `Future<void>`.
  Future<void> clearToken() async {
    await clearAccessToken();
  }
}
