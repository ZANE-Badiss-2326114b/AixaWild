import 'package:drift/native.dart';
import 'package:flutter_application_1/data/api/api_client.dart';
import 'package:flutter_application_1/data/database/my_database.dart' as db;
import 'package:flutter_application_1/data/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRepository API integration', () {
    late db.MyDatabase database;
    late UserRepository repository;
    late String email;
    late String username;
    const String password = 'ApiPass!123';

    setUp(() {
      final runId = DateTime.now().microsecondsSinceEpoch.toString();
      email = 'api_user_$runId@example.com';
      username = 'api-user-$runId';

      database = db.MyDatabase.withExecutor(NativeDatabase.memory());
      repository = UserRepository(ApiClient(), database.userDao);
    });

    tearDown(() async {
      await database.close();
    });

    test('createUser crée un compte via API et persiste localement', () async {
      final result = await repository.createUser(
        email,
        username,
        password,
        typeName: 'premium',
      );
      final local = await database.userDao.getByEmail(email);

      expect(result, isNotNull);
      expect(result!.email, email);
      expect(result.username, username);
      expect(local, isNotNull);
      expect(local!.passwordHash, password);
    });

    test('authenticate valide le compte créé via API', () async {
      await repository.createUser(email, username, password, typeName: 'premium');
      final result = await repository.authenticate(email, password);
      final local = await database.userDao.getByEmail(email);

      expect(result, isTrue);
      expect(local, isNotNull);
      expect(local!.passwordHash, password);
    });

    test('loginAndSync récupère le profil depuis API et synchronise local', () async {
      await repository.createUser(email, username, password, typeName: 'premium');
      final result = await repository.loginAndSync(email, password);
      final local = await database.userDao.getByEmail(email);

      expect(result, isNotNull);
      expect(result!.email, email);
      expect(local, isNotNull);
      expect(local!.passwordHash, password);
    });
  });
}
