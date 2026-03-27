import 'package:flutter_application_1/data/models/user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('User.fromJson', () {
    test('reads type_name in snake_case', () {
      final user = User.fromJson({
        'user_email': 'alice@example.com',
        'username': 'alice',
        'type_name': 'Premium',
      });

      expect(user.typeName, 'Premium');
    });

    test('reads typeName in camelCase', () {
      final user = User.fromJson({
        'email': 'bob@example.com',
        'username': 'bob',
        'typeName': 'Admin',
      });

      expect(user.typeName, 'Admin');
    });

    test('reads nested subscription type when top-level is missing', () {
      final user = User.fromJson({
        'email': 'carol@example.com',
        'username': 'carol',
        'subscription': {
          'type_name': 'Premium',
        },
      });

      expect(user.typeName, 'Premium');
    });
  });
}
