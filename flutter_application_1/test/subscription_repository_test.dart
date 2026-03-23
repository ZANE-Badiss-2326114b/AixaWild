import 'package:flutter_application_1/data/api/api_client.dart';
import 'package:flutter_application_1/data/repositories/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSubscriptionApiClient extends ApiClient {
  _FakeSubscriptionApiClient({required this.responsesByEndpoint});

  final Map<String, dynamic> responsesByEndpoint;

  @override
  Future<dynamic> get(
    String endpoint, {
    bool includeAuthorization = true,
  }) async {
    if (!responsesByEndpoint.containsKey(endpoint)) {
      throw Exception('Endpoint GET non géré en test: $endpoint');
    }

    final response = responsesByEndpoint[endpoint];
    if (response is Exception) {
      throw response;
    }
    return response;
  }
}

void main() {
  group('SubscriptionRepository.getCurrentByUser', () {
    test('fallback sur /subscriptions/user/{email} et lit subscriptionTypeLabel',
        () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      final apiClient = _FakeSubscriptionApiClient(
        responsesByEndpoint: {
          'subscriptions/user/tom%40archlinux.fr/current':
              Exception('404 endpoint inexistant'),
          'subscriptions/user/tom%40archlinux.fr': [
            {
              'userEmail': 'tom@archlinux.fr',
              'subscriptionTypeLabel': 'Admin',
              'subscriptionTypeCode': 'Admin',
              'status': 'ACTIVE',
              'startedAt': tomorrow.toIso8601String(),
            },
            {
              'userEmail': 'tom@archlinux.fr',
              'subscriptionTypeLabel': 'Admin',
              'subscriptionTypeCode': 'Admin',
              'status': 'ACTIVE',
              'startedAt': yesterday.toIso8601String(),
            },
          ],
        },
      );

      final repository = SubscriptionRepository(apiClient);
      final current = await repository.getCurrentByUser('tom@archlinux.fr');

      expect(current, isNotNull);
      expect(current!.currentTypeLabel, 'Admin');
      expect(current.startDate, isNotNull);
      expect(current.startDate!.isAfter(now), isFalse);
    });
  });
}
