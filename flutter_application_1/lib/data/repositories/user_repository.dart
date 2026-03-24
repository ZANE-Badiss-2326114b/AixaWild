import '../api/api_client.dart';
import '../daos/user_dao.dart';
import '../database/my_database.dart';
// import 'package:drift/drift.dart';

class UserRepository {
  final ApiClient _apiClient;
  final UserDao _userDao;

  UserRepository(this._apiClient, this._userDao);

  // L'UI écoute ce stream. Si la DB change (après une sync API), l'UI se met à jour seule.
  Stream<List<User>> get usersStream => _userDao.watchAllUsers();

  /// SYNCHRONISATION : Récupère sur le web et stocke en local
  Future<void> syncUsersFromRemote() async {
    try {
      final List<dynamic> data = await _apiClient.get('users');
      
      for (var json in data) {
        // Centralisation du parsing (évite la répétition dans UserService)
        final userCompanion = UsersCompanion.insert(
          email: json['email'] ?? json['user_email'] ?? '',
          username: json['username'] ?? 'Inconnu',
          passwordHash: json['password_hash'] ?? json['passwordHash'] ?? '',
        );
        await _userDao.upsertUser(userCompanion);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> authenticate(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    bool isAuthenticated;

    if (normalizedEmail.isEmpty || password.isEmpty) {
      isAuthenticated = false;
    } else {
      final authenticatedFromRemote = await _authenticateFromRemote(
        normalizedEmail,
        password,
      );

      if (authenticatedFromRemote) {
        isAuthenticated = true;
      } else {
        isAuthenticated = await _authenticateFromLocal(normalizedEmail, password);
      }
    }

    return isAuthenticated;
  }

  Future<bool> _authenticateFromRemote(
    String normalizedEmail,
    String password,
  ) async {
    bool isAuthenticated;

    try {
      final dynamic response = await _apiClient.get('users');
      if (response is! List) {
        isAuthenticated = false;
      } else {
        isAuthenticated = false;

        for (final user in response) {
          if (isAuthenticated) {
            isAuthenticated = true;
          } else {
            if (user is! Map<String, dynamic>) {
              isAuthenticated = false;
            } else {
              final userEmail = (user['email'] ?? user['user_email'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
              final userPassword = (user['password'] ??
                      user['passwordHash'] ??
                      user['password_hash'] ??
                      '')
                  .toString();

              if (userEmail == normalizedEmail && userPassword == password) {
                isAuthenticated = true;
              } else {
                isAuthenticated = false;
              }
            }
          }
        }
      }
    } catch (_) {
      isAuthenticated = false;
    }

    return isAuthenticated;
  }

  Future<bool> _authenticateFromLocal(
    String normalizedEmail,
    String password,
  ) async {
    bool isAuthenticated;

    try {
      final localUser = await _userDao.getByEmail(normalizedEmail);
      if (localUser == null) {
        isAuthenticated = false;
      } else {
        isAuthenticated = localUser.passwordHash == password;
      }
    } catch (_) {
      isAuthenticated = false;
    }

    return isAuthenticated;
  }

  Future<void> createUser(String email, String username, String password) async {
    final normalizedEmail = email.trim().toLowerCase();

    final userData = {
      'email': normalizedEmail,
      'username': username,
      'passwordHash': password, 
    };

    await _apiClient.post(
      'users',
      userData,
      includeAuthorization: false,
    );
    
    // 2. Mise à jour locale (pour que l'app soit réactive même hors-ligne)
    await _userDao.upsertUser(UsersCompanion.insert(
      email: normalizedEmail,
      username: username,
      passwordHash: password,
    ));
  }
}