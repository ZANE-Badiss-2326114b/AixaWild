import '../api/api_client.dart';
import '../models/subscription.dart';
import '../models/subscription_type.dart';

class SubscriptionDashboardData {
  final Subscription? currentSubscription;
  final List<SubscriptionType> availableTypes;

  SubscriptionDashboardData({
    required this.currentSubscription,
    required this.availableTypes,
  });
}

class SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepository(this._apiClient);

  Future<SubscriptionDashboardData> getDashboardData(String userEmail) async {
    final current = await getCurrentByUser(userEmail);
    final availableTypes = await getAvailableTypes();

    return SubscriptionDashboardData(
      currentSubscription: current,
      availableTypes: availableTypes,
    );
  }

  Future<Subscription?> getCurrentByUser(String userEmail) async {
    final encodedEmail = Uri.encodeComponent(userEmail);
    final endpoints = [
      'subscriptions/user/$encodedEmail/current',
      'subscriptions/user/$encodedEmail',
    ];

    Subscription? currentSubscription;

    for (final endpoint in endpoints) {
      if (currentSubscription == null) {
        try {
          final dynamic response = await _apiClient.get(endpoint);

          if (response is Map<String, dynamic>) {
            currentSubscription = Subscription.fromJson(response);
          } else {
            if (response is List) {
              currentSubscription = _selectCurrentFromList(response);
            } else {
              currentSubscription = null;
            }
          }
        } catch (_) {
          currentSubscription = null;
        }
      }
    }

    return currentSubscription;
  }

  Future<List<SubscriptionType>> getAvailableTypes() async {
    List<SubscriptionType> availableTypes;

    final fromTypesEndpoint = await _getAvailableTypesFromPrimaryEndpoints();
    if (fromTypesEndpoint.isNotEmpty) {
      availableTypes = fromTypesEndpoint;
    } else {
      availableTypes = await _getAvailableTypesFromSubscriptions();
    }

    return availableTypes;
  }

  Future<void> createSubscriptionForUser({
    required String userEmail,
    required SubscriptionType selectedType,
  }) async {
    final normalizedName = selectedType.name.trim().toLowerCase();
    const endpoints = [
      'subscriptions',
      'user-subscriptions',
    ];

    final payload = {
      'userEmail': userEmail,
      'email': userEmail,
      'subscriptionTypeId': selectedType.id,
      'typeId': selectedType.id,
      'subscriptionTypeName': selectedType.name,
      'typeName': selectedType.name,
      'status': 'ACTIVE',
    };

    Exception? lastError;
    bool created = false;

    if (normalizedName == 'free') {
      created = true;
    } else {
      for (final endpoint in endpoints) {
        if (!created) {
          try {
            await _apiClient.post(endpoint, payload);
            created = true;
          } catch (error) {
            if (error is Exception) {
              lastError = error;
              created = false;
            } else {
              created = false;
            }
          }
        }
      }
    }

    if (!created && lastError != null) {
      throw lastError;
    }
  }

  Future<List<SubscriptionType>> _getAvailableTypesFromPrimaryEndpoints() async {
    const endpoints = [
      'subscription-types',
      'subscriptionTypes',
      'subscriptions/types',
      'types/subscriptions',
    ];

    List<SubscriptionType> types = const [];

    for (final endpoint in endpoints) {
      if (types.isEmpty) {
        try {
          final response = await _apiClient.get(endpoint);
          final parsed = _parseTypesResponse(response);

          if (parsed.isNotEmpty) {
            types = _deduplicateTypes(parsed);
          }
        } catch (_) {
        }
      }
    }

    return types;
  }

  Future<List<SubscriptionType>> _getAvailableTypesFromSubscriptions() async {
    List<SubscriptionType> types;

    try {
      final response = await _apiClient.get('subscriptions');
      final fromSubscriptions = _extractTypesFromSubscriptions(response);
      types = _deduplicateTypes(fromSubscriptions);
    } catch (_) {
      types = const [];
    }

    return types;
  }

  List<SubscriptionType> _parseTypesResponse(dynamic response) {
    List<SubscriptionType> parsedTypes;

    final maps = _extractTypeMaps(response);
    if (maps.isEmpty) {
      parsedTypes = const [];
    } else {
      parsedTypes = maps.map(SubscriptionType.fromJson).toList();
    }

    return parsedTypes;
  }

  List<SubscriptionType> _extractTypesFromSubscriptions(dynamic response) {
    List<SubscriptionType> collected;

    if (response is! List) {
      collected = const [];
    } else {
      collected = [];

      for (final item in response) {
        if (item is Map<String, dynamic>) {
          final dynamic nested = item['type'] ?? item['subscriptionType'];
          if (nested is Map<String, dynamic>) {
            collected.add(SubscriptionType.fromJson(nested));
          } else {
            final dynamic typeId = item['subscriptionTypeId'];
            final dynamic typeLabel = item['subscriptionTypeLabel'];
            final dynamic typeCode = item['subscriptionTypeCode'];

            if (typeId != null || typeLabel != null || typeCode != null) {
              collected.add(
                SubscriptionType.fromJson({
                  'id': typeId,
                  'label': typeLabel,
                  'code': typeCode,
                }),
              );
            }
          }
        }
      }
    }

    return collected;
  }

  List<Map<String, dynamic>> _extractTypeMaps(
    dynamic node, {
    int depth = 0,
  }) {
    List<Map<String, dynamic>> collected;

    if (node == null || depth > 6) {
      collected = const [];
    } else {
      if (node is List) {
        collected = [];
        for (final item in node) {
          collected.addAll(_extractTypeMaps(item, depth: depth + 1));
        }
      } else {
        if (node is! Map<String, dynamic>) {
          collected = const [];
        } else {
          collected = [];

          if (_looksLikeSubscriptionTypeMap(node)) {
            collected.add(node);
          }

          final nestedCandidates = <dynamic>[
            node['content'],
            node['data'],
            node['items'],
            node['results'],
            node['types'],
            node['subscriptionTypes'],
            node['subscriptions'],
            node['_embedded'],
            node['type'],
            node['subscriptionType'],
          ];

          for (final candidate in nestedCandidates) {
            collected.addAll(_extractTypeMaps(candidate, depth: depth + 1));
          }
        }
      }
    }

    return collected;
  }

  bool _looksLikeSubscriptionTypeMap(Map<String, dynamic> map) {
    final hasName = map.containsKey('label') ||
        map.containsKey('code') ||
        map.containsKey('subscriptionTypeLabel') ||
        map.containsKey('subscriptionTypeCode');

    final hasTypeId = map.containsKey('id') || map.containsKey('subscriptionTypeId');

    return hasName || hasTypeId;
  }

  List<SubscriptionType> _deduplicateTypes(List<SubscriptionType> source) {
    final Map<String, SubscriptionType> unique = {};

    for (final type in source) {
      final normalizedName = type.name.trim().toLowerCase();
      final key = '${type.id ?? 'null'}::$normalizedName';
      unique[key] = type;
    }

    return unique.values.toList();
  }

  Subscription? _selectCurrentFromList(List<dynamic> response) {
    Subscription? selected;

    final subscriptions = response
        .whereType<Map<String, dynamic>>()
        .map(Subscription.fromJson)
        .toList();

    if (subscriptions.isEmpty) {
      selected = null;
    } else {
      final now = DateTime.now();

      bool isActive(Subscription subscription) {
        final statusIsActive =
            (subscription.status ?? '').toUpperCase().trim() == 'ACTIVE';
        return subscription.active || statusIsActive;
      }

      bool isValidNow(Subscription subscription) {
        final startsOk =
            subscription.startDate == null || !subscription.startDate!.isAfter(now);
        final endsOk =
            subscription.endDate == null || subscription.endDate!.isAfter(now);
        return startsOk && endsOk;
      }

      int compareByStartDateDesc(Subscription a, Subscription b) {
        int comparison;
        final aDate = a.startDate;
        final bDate = b.startDate;

        if (aDate == null && bDate == null) {
          comparison = 0;
        } else {
          if (aDate == null) {
            comparison = 1;
          } else {
            if (bDate == null) {
              comparison = -1;
            } else {
              comparison = bDate.compareTo(aDate);
            }
          }
        }

        return comparison;
      }

      final activeAndValidNow = subscriptions
          .where((subscription) => isActive(subscription) && isValidNow(subscription))
          .toList()
        ..sort(compareByStartDateDesc);

      if (activeAndValidNow.isNotEmpty) {
        selected = activeAndValidNow.first;
      } else {
        final active = subscriptions.where(isActive).toList()
          ..sort(compareByStartDateDesc);

        if (active.isNotEmpty) {
          selected = active.first;
        } else {
          subscriptions.sort(compareByStartDateDesc);
          selected = subscriptions.first;
        }
      }
    }

    return selected;
  }
}
