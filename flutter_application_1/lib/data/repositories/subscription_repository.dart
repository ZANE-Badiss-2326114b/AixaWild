import '../api/api_client.dart';
import '../models/subscription.dart';
import '../models/subscription_type.dart';
import '../utils/api_endpoints.dart';

class SubscriptionRepository {
	final ApiClient _apiClient;

	SubscriptionRepository(this._apiClient);

	Future<List<SubscriptionType>> getAvailableTypes() async {
		List<SubscriptionType> types;

		try {
			final response = await _apiClient.get(
				ApiEndpoints.subscriptionTypes,
				includeAuthorization: false,
			);
			types = _mapTypesFromResponse(response);
		} catch (_) {
			try {
				final fallbackResponse = await _apiClient.get(
					ApiEndpoints.subscriptionTypesFallback,
					includeAuthorization: false,
				);
				types = _mapTypesFromResponse(fallbackResponse);
			} catch (_) {
				types = <SubscriptionType>[];
			}
		}

		return types;
	}

	Future<Subscription?> getCurrentByUser(String email) async {
		Subscription? currentSubscription;
		final encodedEmail = Uri.encodeComponent(email);

		try {
			final response = await _apiClient.get(
				ApiEndpoints.currentSubscriptionByUser(encodedEmail),
			);

			if (response is Map<String, dynamic>) {
				currentSubscription = Subscription.fromJson(response);
			} else {
				currentSubscription = null;
			}
		} catch (_) {
			try {
				final fallbackResponse = await _apiClient.get(
					ApiEndpoints.subscriptionsByUser(encodedEmail),
				);

				if (fallbackResponse is List) {
					if (fallbackResponse.isNotEmpty) {
						Subscription? selected;

						for (final item in fallbackResponse) {
							if (item is Map<String, dynamic>) {
								final candidate = Subscription.fromJson(item);
								if (selected == null) {
									selected = candidate;
								} else {
									final selectedDate = selected.startDate;
									final candidateDate = candidate.startDate;

									if (selectedDate == null) {
										if (candidateDate != null) {
											selected = candidate;
										} else {
											selected = selected;
										}
									} else {
										if (candidateDate != null) {
											if (candidateDate.isAfter(selectedDate)) {
												selected = candidate;
											} else {
												selected = selected;
											}
										} else {
											selected = selected;
										}
									}
								}
							} else {
								currentSubscription = null;
							}
						}

						currentSubscription = selected;
					} else {
						currentSubscription = null;
					}
				} else {
					if (fallbackResponse is Map<String, dynamic>) {
						currentSubscription = Subscription.fromJson(fallbackResponse);
					} else {
						currentSubscription = null;
					}
				}
			} catch (_) {
				currentSubscription = null;
			}
		}

		return currentSubscription;
	}

	Future<SubscriptionDashboardData> getDashboardData(String email) async {
		final availableTypes = await getAvailableTypes();

		Subscription? currentSubscription;
		if (email.trim().isNotEmpty) {
			currentSubscription = await getCurrentByUser(email);
		} else {
			currentSubscription = null;
		}

		return SubscriptionDashboardData(
			currentSubscription: currentSubscription,
			availableTypes: availableTypes,
		);
	}

	List<SubscriptionType> _mapTypesFromResponse(dynamic response) {
		List<SubscriptionType> types;

		if (response is List) {
			final parsedTypes = <SubscriptionType>[];
			for (final item in response) {
				if (item is Map<String, dynamic>) {
					parsedTypes.add(SubscriptionType.fromJson(item));
				} else {
					parsedTypes.add(
						SubscriptionType(
							id: null,
							name: 'Free',
							description: null,
							price: null,
						),
					);
				}
			}

			final normalized = <SubscriptionType>[];
			for (final type in parsedTypes) {
				final exists = normalized.any(
					(existing) =>
							existing.name.trim().toLowerCase() == type.name.trim().toLowerCase(),
				);

				if (exists) {
					normalized.addAll(const <SubscriptionType>[]);
				} else {
					normalized.add(type);
				}
			}

			types = normalized;
		} else {
			if (response is Map<String, dynamic>) {
				if (response['data'] is List) {
					final dataList = response['data'] as List;
					final parsedTypes = <SubscriptionType>[];
					for (final item in dataList) {
						if (item is Map<String, dynamic>) {
							parsedTypes.add(SubscriptionType.fromJson(item));
						} else {
							parsedTypes.add(
								SubscriptionType(
									id: null,
									name: 'Free',
									description: null,
									price: null,
								),
							);
						}
					}
					types = parsedTypes;
				} else {
					types = <SubscriptionType>[];
				}
			} else {
				types = <SubscriptionType>[];
			}
		}

		return types;
	}
}
