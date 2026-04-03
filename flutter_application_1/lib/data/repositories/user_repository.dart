import 'package:drift/drift.dart';

import '../api/api_client.dart';
import '../daos/user_dao.dart';
import '../database/my_database.dart' as db;
import '../models/user.dart';
import '../utils/api_endpoints.dart';

class UserRepository {
  final ApiClient _apiClient;
  final UserDao _userDao;

  UserRepository(this._apiClient, this._userDao);

  Future<User?> createUser(
    String email,
    String username,
    String password, {
    String? typeName,
  }) async {
    User? createdUser;

    final normalizedTypeName = typeName?.trim().toLowerCase() ?? '';
    final shouldSendTypeName =
        normalizedTypeName.isNotEmpty && normalizedTypeName != 'free';

    final payload = <String, dynamic>{
      'email': email,
      'username': username,
      'password': password,
    };

    if (shouldSendTypeName) {
      payload['typeName'] = normalizedTypeName;
    }

    final response = await _apiClient.post(
      ApiEndpoints.users,
      payload,
      includeAuthorization: false,
    );

    if (response is Map<String, dynamic>) {
      final remoteUser = User.fromJson(response);
      await _userDao.upsertUser(
        db.UsersCompanion.insert(
          email: remoteUser.email,
          username: remoteUser.username,
          passwordHash: password,
          typeName: Value(remoteUser.typeName),
          createdAt: Value(remoteUser.createdAt),
        ),
      );
      createdUser = remoteUser;
    } else {
      await _userDao.upsertUser(
        db.UsersCompanion.insert(
          email: email,
          username: username,
          passwordHash: password,
        ),
      );
      createdUser = User(
        email: email,
        username: username,
        typeName: shouldSendTypeName ? normalizedTypeName : null,
      );
    }

    return createdUser;
  }

  Future<bool> authenticate(String email, String password) async {
    bool isAuthenticated;

    ApiClient.setCredentials(email: email, password: password);

    try {
      final response = await _apiClient.get(ApiEndpoints.userDetails(email));

      if (response is Map<String, dynamic>) {
        final remoteUser = User.fromJson(response);

        await _userDao.upsertUser(
          db.UsersCompanion.insert(
            email: remoteUser.email,
            username: remoteUser.username,
            passwordHash: password,
            typeName: Value(remoteUser.typeName),
            createdAt: Value(remoteUser.createdAt),
          ),
        );

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

    ApiClient.setCredentials(email: email, password: password);

    try {
      final response = await _apiClient.get(ApiEndpoints.userDetails(email));

      if (response is Map<String, dynamic>) {
        final remoteUser = User.fromJson(response);

        await _userDao.upsertUser(
          db.UsersCompanion.insert(
            email: remoteUser.email,
            username: remoteUser.username,
            passwordHash: password,
            typeName: Value(remoteUser.typeName),
            createdAt: Value(remoteUser.createdAt),
          ),
        );

        syncedUser = remoteUser;
      } else {
        final localUser = await _userDao.getByEmail(email);
        if (localUser != null) {
          if (localUser.passwordHash == password) {
            syncedUser = User(
              email: localUser.email,
              username: localUser.username,
            );
          } else {
            syncedUser = null;
          }
        } else {
          syncedUser = null;
        }
      }
    } catch (e) {
      final errorText = e.toString();
      final isUnauthorized =
          errorText.contains('Erreur API (401)') ||
          errorText.contains('Erreur API (403)');

      if (isUnauthorized) {
        ApiClient.clearCredentials();
        return null;
      }

      final localUser = await _userDao.getByEmail(email);
      if (localUser != null) {
        if (localUser.passwordHash == password) {
          syncedUser = User(
            email: localUser.email,
            username: localUser.username,
          );
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
    ApiClient.clearCredentials();
    // Optionnel : supprimer les données locales au logout
    // await _userDao.clearAll(); 
  }
}