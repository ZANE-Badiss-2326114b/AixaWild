import 'package:flutter_application_1/data/api/core/api_interface.dart';
import 'package:flutter_application_1/data/repositories/subscription_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSubscriptionApiClient implements IApiClient {
  _FakeSubscriptionApiClient({required this.responsesByEndpoint});

  final Map<String, dynamic> responsesByEndpoint;

  @override
  Future<dynamic> get(String endpoint, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    if (!responsesByEndpoint.containsKey(endpoint)) {
      throw Exception('Endpoint GET non géré en test: $endpoint');
    }

    final response = responsesByEndpoint[endpoint];
    if (response is Exception) {
      throw response;
    }

    if (response is List) {
      return response.map((item) => item is Map ? Map<String, dynamic>.from(item) : item).toList();
    }

    if (response is Map) {
      return Map<String, dynamic>.from(response);
    }

    return response;
  }

  @override
  Future<dynamic> post(String endpoint, dynamic data, {Map<String, String>? headers, bool includeAuthorization = true}) async {
    throw UnimplementedError('POST non utilisé dans ce test: $endpoint');
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
  group('SubscriptionRepository.getCurrentByUser', () {
    test('fallback sur /subscriptions/user/{email} et lit subscriptionTypeLabel', () async {
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      final tomorrow = now.add(const Duration(days: 1));

      final apiClient = _FakeSubscriptionApiClient(
        responsesByEndpoint: {
          '/subscriptions/user/tom%40archlinux.fr/current': <String, dynamic>{'id': 1, 'userEmail': 'tom@archlinux.fr', 'subscriptionTypeLabel': 'Admin', 'subscriptionTypeCode': 'Admin', 'status': 'ACTIVE', 'startedAt': tomorrow.toIso8601String()},
          '/subscriptions/user/tom%40archlinux.fr': [
            <String, dynamic>{'id': 1, 'userEmail': 'tom@archlinux.fr', 'subscriptionTypeLabel': 'Admin', 'subscriptionTypeCode': 'Admin', 'status': 'ACTIVE', 'startedAt': tomorrow.toIso8601String()},
            <String, dynamic>{'id': 2, 'userEmail': 'tom@archlinux.fr', 'subscriptionTypeLabel': 'Admin', 'subscriptionTypeCode': 'Admin', 'status': 'ACTIVE', 'startedAt': yesterday.toIso8601String()},
          ],
        },
      );

      final repository = SubscriptionRepository(apiClient);
      final current = await repository.getCurrentByUser('tom@archlinux.fr');

      expect(current, isNotNull);
      expect(current!.currentTypeLabel, 'Admin');
      expect(current.startDate, isNotNull);
      expect(current.startDate!.isAfter(now), isTrue);
    });
  });
}
