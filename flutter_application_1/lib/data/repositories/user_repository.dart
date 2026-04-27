import 'package:drift/drift.dart';

import 'package:flutter_application_1/data/api/auth/auth_token_manager.dart';
import 'package:flutter_application_1/data/api/auth/session_service.dart';
import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/daos/user_dao.dart';
import 'package:flutter_application_1/data/database/my_database.dart' as db;
import 'package:flutter_application_1/data/models/user.dart';
import 'package:flutter_application_1/data/models/user_identity.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

class UserRepository {
  final IApiClient _apiClient;
  final UserDao _userDao;
  final SessionService _sessionService;

  UserRepository(this._apiClient, this._userDao, {SessionService? sessionService})
      : _sessionService = sessionService ?? SessionService();

  Future<UserIdentity?> currentUserIdentity() async {
    UserIdentity? identity;

    identity = await _sessionService.currentUser();

    return identity;
  }

  Future<void> _authenticateAndStoreToken(String email, String password) async {
    final response = await _apiClient.post(
      ApiEndpoints.authLogin, 
      <String, String>{'email': email.trim(), 'password': password}, 
      includeAuthorization: false
    );

    // 1. DEBUG CRITIQUE : On affiche la réponse brute du serveur
    print("🚀 RÉPONSE BRUTE SPRING BOOT : $response");

    if (response is! Map<String, dynamic>) {
      throw Exception('Réponse de login invalide. Type reçu: ${response.runtimeType}');
    }

    // 2. EXTRACTION TOLÉRANTE : On cherche les clés les plus courantes
    final token = (response['token'] ?? response['accessToken'] ?? response['jwt'] ?? '').toString().trim();
    
    if (token.isEmpty) {
      throw Exception('Token absent. Clés disponibles dans le JSON: ${response.keys}');
    }

    // 3. SAUVEGARDE
    await AuthTokenManager.instance.saveToken(token);
    print("✅ TOKEN SAUVEGARDÉ AVEC SUCCÈS !");
  }

  Future<User?> createUser(String email, String username, String password, {String? typeName}) async {
    User? createdUser;

    final normalizedTypeName = typeName?.trim().toLowerCase() ?? '';
    final shouldSendTypeName = normalizedTypeName.isNotEmpty && normalizedTypeName != 'free';

    final payload = <String, dynamic>{'email': email, 'username': username, 'password': password};

    if (shouldSendTypeName) {
      payload['typeName'] = normalizedTypeName;
    }

    final response = await _apiClient.post(ApiEndpoints.users, payload, includeAuthorization: false);

    if (response is Map<String, dynamic>) {
      final remoteUser = User.fromJson(response);
      await _userDao.upsertUser(db.UsersCompanion.insert(email: remoteUser.email, username: remoteUser.username, passwordHash: password, typeName: Value(remoteUser.typeName), createdAt: Value(remoteUser.createdAt)));
      createdUser = remoteUser;
    } else {
      await _userDao.upsertUser(db.UsersCompanion.insert(email: email, username: username, passwordHash: password));
      createdUser = User(email: email, username: username, typeName: shouldSendTypeName ? normalizedTypeName : null);
    }

    return createdUser;
  }

  Future<bool> authenticate(String email, String password) async {
    bool isAuthenticated;

    try {
      await _authenticateAndStoreToken(email, password);

      final response = await _apiClient.get(ApiEndpoints.userDetails(email));

      if (response is Map<String, dynamic>) {
        final remoteUser = User.fromJson(response);

        await _userDao.upsertUser(db.UsersCompanion.insert(email: remoteUser.email, username: remoteUser.username, passwordHash: password, typeName: Value(remoteUser.typeName), createdAt: Value(remoteUser.createdAt)));

        isAuthenticated = true;
      } else {
        final localUser = await _userDao.getByEmail(email);
        if (localUser != null) {
          if (localUser.passwordHash == password) {
            isAuthenticated = true;
          } else {
            isAuthenticated = false;
          }
        } else {
          isAuthenticated = false;
        }
      }
    } catch (_) {
      final localUser = await _userDao.getByEmail(email);
      if (localUser != null) {
        if (localUser.passwordHash == password) {
          isAuthenticated = true;
        } else {
          isAuthenticated = false;
        }
      } else {
        isAuthenticated = false;
      }
    }

    return isAuthenticated;
  }

  // Authentification et sauvegarde locale du profil
  Future<User?> loginAndSync(String email, String password) async {
    User? syncedUser;

    try {
      await _authenticateAndStoreToken(email, password);

      final response = await _apiClient.get(ApiEndpoints.userDetails(email));

      if (response is Map<String, dynamic>) {
        final remoteUser = User.fromJson(response);

        await _userDao.upsertUser(db.UsersCompanion.insert(email: remoteUser.email, username: remoteUser.username, passwordHash: password, typeName: Value(remoteUser.typeName), createdAt: Value(remoteUser.createdAt)));

        syncedUser = remoteUser;
      } else {
        final localUser = await _userDao.getByEmail(email);
        if (localUser != null) {
          if (localUser.passwordHash == password) {
            syncedUser = User(email: localUser.email, username: localUser.username);
          } else {
            syncedUser = null;
          }
        } else {
          syncedUser = null;
        }
      }
    } catch (e) {
      final errorText = e.toString();
      final isUnauthorized = errorText.contains('Erreur API (401)') || errorText.contains('Erreur API (403)');
      /////////////////
      print("❌ ERREUR LORS DU LOGIN API : $e");
      /////////////////
      if (isUnauthorized) {
        await AuthTokenManager.instance.clearToken();
        return null;
      }

      final localUser = await _userDao.getByEmail(email);
      if (localUser != null) {
        if (localUser.passwordHash == password) {
          syncedUser = User(email: localUser.email, username: localUser.username);
        } else {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    return syncedUser;
  }

  Future<void> logout() async {
    await AuthTokenManager.instance.clearToken();
    // Optionnel : supprimer les données locales au logout
    // await _userDao.clearAll();
  }

  Future<List<User>> getAllUsers() async {
    final response = await _apiClient.get(ApiEndpoints.users);

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().map(User.fromJson).toList();
    }

    return <User>[];
  }

  Future<User?> getUserProfile(String email) async {
    final response = await _apiClient.get(ApiEndpoints.userDetails(email));

    if (response is Map<String, dynamic>) {
      return User.fromJson(response);
    }

    return null;
  }

  Future<void> deleteUserByEmail(String email) async {
    await _apiClient.delete(ApiEndpoints.userDetails(email));
  }
}
