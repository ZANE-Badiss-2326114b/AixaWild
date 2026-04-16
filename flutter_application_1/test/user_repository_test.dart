import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/database/my_database.dart' as db;
import 'package:flutter_application_1/data/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const MethodChannel _secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

class _FakeUserApiClient implements IApiClient {
  _FakeUserApiClient();

  final Map<String, Map<String, dynamic>> _usersByEmail = <String, Map<String, dynamic>>{};

  @override
  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    if (endpoint == '/users') {
      final payload = Map<String, dynamic>.from(data as Map);
      final email = payload['email']?.toString() ?? '';
      final username = payload['username']?.toString() ?? '';
      final typeName = payload['typeName']?.toString();

      final response = <String, dynamic>{'email': email, 'username': username, if (typeName != null && typeName.isNotEmpty) 'typeName': typeName, 'created_at': DateTime.now().toIso8601String()};

      _usersByEmail[email] = response;
      return response;
    }

    if (endpoint == '/auth/login') {
      final payload = Map<String, dynamic>.from(data as Map);
      final email = payload['email']?.toString() ?? '';
      final password = payload['password']?.toString() ?? '';
      final user = _usersByEmail[email];

      if (user == null || password.isEmpty) {
        throw Exception('Erreur API (401): identifiants invalides');
      }

      return <String, dynamic>{'token': 'fake-token-for-$email'};
    }

    throw Exception('Endpoint POST non géré en test: $endpoint');
  }

  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    final match = RegExp(r'^/users/([^/]+)$').firstMatch(endpoint);
    if (match != null) {
      final decodedEmail = Uri.decodeComponent(match.group(1) ?? '');
      final user = _usersByEmail[decodedEmail];
      if (user == null) {
        throw Exception('Utilisateur introuvable: $decodedEmail');
      }

      return user;
    }

    throw Exception('Endpoint GET non géré en test: $endpoint');
  }

  @override
  Future<dynamic> put(String endpoint, dynamic data, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    throw UnimplementedError('PUT non utilisé dans ce test: $endpoint');
  }

  @override
  Future<dynamic> delete(String endpoint, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    throw UnimplementedError('DELETE non utilisé dans ce test: $endpoint');
  }

  @override
  Future<dynamic> upload(String endpoint, List<int> bytes, {required String fileName, String? mimeType, Map<String, String>? headers, bool includeAuthorization = true, void Function(int sent, int total)? onSendProgress}) async {
    throw UnimplementedError('UPLOAD non utilisé dans ce test: $endpoint');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Map<String, String?> storage = <String, String?>{};

  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(_secureStorageChannel, (MethodCall call) async {
    switch (call.method) {
      case 'write':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final key = args['key']?.toString() ?? '';
        final value = args['value']?.toString();
        storage[key] = value;
        return null;
      case 'read':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final key = args['key']?.toString() ?? '';
        return storage[key];
      case 'delete':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final key = args['key']?.toString() ?? '';
        storage.remove(key);
        return null;
      case 'deleteAll':
        storage.clear();
        return null;
      default:
        return null;
    }
  });

  group('UserRepository API integration', () {
    late db.MyDatabase database;
    late UserRepository repository;
    late _FakeUserApiClient apiClient;
    late String email;
    late String username;
    const String password = 'ApiPass!123';

    setUp(() async {
      storage.clear();
      final runId = DateTime.now().microsecondsSinceEpoch.toString();
      email = 'api_user_$runId@example.com';
      username = 'api-user-$runId';

      database = db.MyDatabase.withExecutor(NativeDatabase.memory());
      apiClient = _FakeUserApiClient();
      repository = UserRepository(apiClient, database.userDao);
    });

    tearDown(() async {
      storage.clear();
      await database.close();
    });

    test('createUser crée un compte via API et persiste localement', () async {
      final result = await repository.createUser(email, username, password, typeName: 'premium');
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
