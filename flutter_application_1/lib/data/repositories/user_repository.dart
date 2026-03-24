import '../api/api_client.dart';
import '../daos/user_dao.dart';
import '../database/my_database.dart';

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
      print("Erreur de synchronisation : $e");
      rethrow;
    }
  }
  Future<void> createUser(String email, String username, String password) async {
    final userData = {
      'email': email,
      'username': username,
      'passwordHash': password, 
    };

    await _apiClient.post('users', userData);
    
    // 2. Mise à jour locale (pour que l'app soit réactive même hors-ligne)
    await _userDao.upsertUser(UsersCompanion.insert(
      email: email,
      username: username,
      passwordHash: password,
    ));
  }
}