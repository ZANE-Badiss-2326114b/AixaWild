import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_application_1/data/database/my_database.dart';
import 'package:flutter_application_1/data/api/api_client.dart';
import 'package:flutter_application_1/data/repositories/user_repository.dart';

class _FakeApiClient extends ApiClient {
  final List<Map<String, dynamic>> _remoteUsers = [
    {'email': 'remote1@example.com', 'username': 'RemoteUser1', 'password_hash': 'hash_remote_1'},
  ];

  @override
  Future<dynamic> get(String endpoint) async {
    if (endpoint == 'users' || endpoint == '/users') {
      return _remoteUsers;
    }
    throw Exception('Endpoint GET non géré en test: $endpoint');
  }

  @override
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    if (endpoint == 'users' || endpoint == '/users') {
      _remoteUsers.add(Map<String, dynamic>.from(data));
      return {'ok': true};
    }
    throw Exception('Endpoint POST non géré en test: $endpoint');
  }
}

void main() {
  late MyDatabase database;
  late UserRepository userRepository;
  late ApiClient apiClient;

  setUp(() {
    // On utilise une base de données en mémoire pour les tests (elle s'efface après chaque test)
    database = MyDatabase.withExecutor(NativeDatabase.memory());
    // apiClient = _FakeApiClient();
    apiClient = ApiClient();
    userRepository = UserRepository(apiClient, database.userDao);
  });

  tearDown(() async {
    await database.close();
  });

  group('User Repository Tests', () {
    test('La synchronisation API doit remplir la base de données locale', () async {
      // 1. Vérifier que la DB est vide au départ
      final initialUsers = await database.userDao.getAllUsers();
      expect(initialUsers.length, 0);

      // 2. Lancer la synchronisation
      print("Démarrage de la synchronisation...");
      await userRepository.syncUsersFromRemote();

      // 3. Vérifier que des données ont été insérées
      final users = await database.userDao.getAllUsers();
      print("Utilisateurs en base après sync : ${users.length}");

      expect(users.length, isPositive);
      expect(users.first.email, isNotEmpty);
    });

    test('L\'insertion manuelle via Repository fonctionne', () async {
      const testEmail = 'test@example.com';

      await userRepository.createUser(testEmail, 'TestUser', 'hashed_password');

      final user = await database.userDao.getByEmail(testEmail);
      expect(user, isNotNull);
      expect(user?.username, 'TestUser');
    });
  });
}
