import 'package:drift/drift.dart';

import 'package:flutter_application_1/data/api/auth/auth_token_manager.dart';
import 'package:flutter_application_1/data/api/auth/session_service.dart';
import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/daos/user_dao.dart';
import 'package:flutter_application_1/data/database/my_database.dart' as db;
import 'package:flutter_application_1/data/models/user.dart';
import 'package:flutter_application_1/data/models/user_identity.dart';
import 'package:flutter_application_1/data/utils/api_endpoints.dart';

/// Repository utilisateur (source distante + source locale).
///
/// Responsabilités:
/// - orchestrer l'authentification via API,
/// - persister/synchroniser les données utilisateur dans Drift,
/// - appliquer un fallback offline sur la base locale en cas d'échec réseau.
class UserRepository {
  final IApiClient _apiClient;
  final UserDao _userDao;
  final SessionService _sessionService;

  /// Construit le repository utilisateur.
  ///
  /// [apiClient] exécute les appels HTTP.
  /// [userDao] gère la persistence locale Drift.
  /// [sessionService] résout l'identité courante depuis le token.
  UserRepository(this._apiClient, this._userDao, {SessionService? sessionService}) : _sessionService = sessionService ?? SessionService();

  /// Retourne l'identité courante issue du token JWT.
  ///
  /// Retourne un [UserIdentity] si token valide, sinon `null`.
  Future<UserIdentity?> currentUserIdentity() async {
    UserIdentity? identity;

    identity = await _sessionService.currentUser();

    return identity;
  }

  /// Authentifie un utilisateur et persiste le token d'accès.
  ///
  /// [email] identifie l'utilisateur côté API.
  /// [password] est envoyé au endpoint d'authentification.
  /// Retourne `Future<void>` si succès, sinon lève une exception.
  Future<void> _authenticateAndStoreToken(String email, String password) async {
    final response = await _apiClient.post(ApiEndpoints.authLogin, <String, String>{'email': email.trim(), 'password': password}, includeAuthorization: false);

    // Diagnostic de contrat API pour identifier rapidement un payload inattendu.
    print("🚀 RÉPONSE BRUTE SPRING BOOT : $response");

    if (response is! Map<String, dynamic>) {
      throw Exception('Réponse de login invalide. Type reçu: ${response.runtimeType}');
    }

    // Extraction tolérante pour compatibilité avec variantes de payload backend.
    final token = (response['token'] ?? response['accessToken'] ?? response['jwt'] ?? '').toString().trim();

    if (token.isEmpty) {
      throw Exception('Token absent. Clés disponibles dans le JSON: ${response.keys}');
    }

    // Persistance centralisée du token pour injection automatique dans Dio.
    await AuthTokenManager.instance.saveToken(token);
    print("✅ TOKEN SAUVEGARDÉ AVEC SUCCÈS !");
  }

  /// Crée un utilisateur distant puis synchronise le cache local.
  ///
  /// [email] email du compte.
  /// [username] nom d'affichage.
  /// [password] mot de passe brut (persisté localement pour fallback offline).
  /// [typeName] type d'abonnement optionnel.
  /// Retourne le [User] créé, distant ou local de secours.
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

  /// Authentifie un utilisateur avec fallback offline.
  ///
  /// [email] identifie le compte.
  /// [password] est validé d'abord via API, puis localement en fallback.
  /// Retourne `true` si authentification valide, sinon `false`.
  Future<bool> authenticate(String email, String password) async {
    bool isAuthenticated;

    try {
      // Chemin nominal: auth distante + hydratation locale.
      await _authenticateAndStoreToken(email, password);

      final response = await _apiClient.get(ApiEndpoints.userDetails(email));

      if (response is Map<String, dynamic>) {
        final remoteUser = User.fromJson(response);

        await _userDao.upsertUser(db.UsersCompanion.insert(email: remoteUser.email, username: remoteUser.username, passwordHash: password, typeName: Value(remoteUser.typeName), createdAt: Value(remoteUser.createdAt)));

        isAuthenticated = true;
      } else {
        // Si le backend renvoie un format inattendu, fallback local explicite.
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
      // Mode dégradé offline: validation stricte sur le cache local.
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

  /// Authentifie l'utilisateur puis synchronise son profil localement.
  ///
  /// [email] identifie le compte.
  /// [password] est utilisé pour l'auth API et fallback local.
  /// Retourne le [User] synchronisé ou `null` en cas d'identifiants invalides.
  Future<User?> loginAndSync(String email, String password) async {
    User? syncedUser;

    try {
      // Chemin nominal: login API puis lecture du profil serveur.
      await _authenticateAndStoreToken(email, password);

      final response = await _apiClient.get(ApiEndpoints.userDetails(email));

      if (response is Map<String, dynamic>) {
        final remoteUser = User.fromJson(response);

        await _userDao.upsertUser(db.UsersCompanion.insert(email: remoteUser.email, username: remoteUser.username, passwordHash: password, typeName: Value(remoteUser.typeName), createdAt: Value(remoteUser.createdAt)));

        syncedUser = remoteUser;
      } else {
        // Fallback local si payload API inattendu.
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

      // Trace utile pour diagnostiquer les erreurs d'auth distante.
      print("❌ ERREUR LORS DU LOGIN API : $e");

      if (isUnauthorized) {
        // En cas d'identifiants invalides, suppression proactive du token local.
        await AuthTokenManager.instance.clearToken();
        return null;
      }

      // En cas d'erreur réseau/technique, tentative de continuité via cache local.
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

  /// Déconnecte l'utilisateur courant.
  ///
  /// Retourne `Future<void>` après suppression du token local.
  Future<void> logout() async {
    await AuthTokenManager.instance.clearToken();
    // Optionnel: purge complète du cache local si politique sécurité renforcée.
    // await _userDao.clearAll();
  }

  /// Charge la liste des utilisateurs depuis l'API.
  ///
  /// Retourne une liste de [User], vide si réponse invalide.
  Future<List<User>> getAllUsers() async {
    final response = await _apiClient.get(ApiEndpoints.users);

    if (response is List) {
      return response.whereType<Map<String, dynamic>>().map(User.fromJson).toList();
    }

    return <User>[];
  }

  /// Charge le profil d'un utilisateur depuis l'API.
  ///
  /// [email] est encodé par [ApiEndpoints.userDetails].
  /// Retourne un [User] si trouvé, sinon `null`.
  Future<User?> getUserProfile(String email) async {
    final response = await _apiClient.get(ApiEndpoints.userDetails(email));

    if (response is Map<String, dynamic>) {
      return User.fromJson(response);
    }

    return null;
  }

  /// Supprime un utilisateur côté API.
  ///
  /// [email] identifie le compte à supprimer.
  /// Retourne `Future<void>`.
  Future<void> deleteUserByEmail(String email) async {
    await _apiClient.delete(ApiEndpoints.userDetails(email));
  }
}
