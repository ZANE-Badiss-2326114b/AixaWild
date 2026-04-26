import 'package:drift/drift.dart';

import 'package:flutter_application_1/data/api/auth/auth_token_manager.dart';
import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/daos/user_dao.dart';
import 'package:flutter_application_1/data/database/my_database.dart' as db;
import 'package:flutter_application_1/data/models/user.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

class UserRepository {
  final IApiClient _apiClient;
  final UserDao _userDao;

  UserRepository(this._apiClient, this._userDao);

  Future<void> _authenticateAndStoreToken(String email, String password) async {
    final response = await _apiClient.post(ApiEndpoints.authLogin, <String, String>{'email': email.trim(), 'password': password}, includeAuthorization: false);

    if (response is! Map<String, dynamic>) {
      throw Exception('Réponse de login invalide');
    }

    final token = (response['token'] ?? '').toString().trim();
    if (token.isEmpty) {
      throw Exception('Token absent dans la réponse de login');
    }

    await AuthTokenManager.instance.saveToken(token);
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
    await AuthTokenManager.instance.clearOnLogout();
    // Optionnel : supprimer les données locales au logout
    // await _userDao.clearAll();
  }

  Future<void> requestPasswordReset(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw Exception('Email manquant pour la réinitialisation.');
    }

    await _apiClient.post(
      ApiEndpoints.authForgotPassword,
      <String, String>{'email': normalizedEmail},
      includeAuthorization: false,
    );
  }
}
