import 'package:flutter_application_1/data/models/subscription_type.dart';
import 'package:flutter_application_1/data/utils/json_parser.dart';

class Subscription {
  final String currentTypeLabel;
  final String? status;
  final DateTime? startDate;
  final DateTime? endDate;

  Subscription({
    required this.currentTypeLabel,
    this.status,
    this.startDate,
    this.endDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    String parsedLabel;
    final rawLabel =
        json['subscriptionTypeLabel'] ?? json['subscriptionTypeCode'] ?? json['type_name'];
    final normalizedLabel = JsonParser.asString(rawLabel);

    if (normalizedLabel.isNotEmpty) {
      parsedLabel = normalizedLabel;
    } else {
      parsedLabel = 'Free';
    }

    String? parsedStatus;
    final rawStatus = json['status'];
    final normalizedStatus = JsonParser.asString(rawStatus);
    if (normalizedStatus.isNotEmpty) {
      parsedStatus = normalizedStatus;
    } else {
      parsedStatus = null;
    }

    DateTime? parsedStartDate;
    final startValue = json['startedAt'] ?? json['startDate'];
    parsedStartDate = JsonParser.toDate(startValue);

    DateTime? parsedEndDate;
    final endValue = json['endedAt'] ?? json['endDate'];
    parsedEndDate = JsonParser.toDate(endValue);

    return Subscription(
      currentTypeLabel: parsedLabel,
      status: parsedStatus,
      startDate: parsedStartDate,
      endDate: parsedEndDate,
    );
  }
}

class SubscriptionDashboardData {
  final Subscription? currentSubscription;
  final List<SubscriptionType> availableTypes;

  SubscriptionDashboardData({
    required this.currentSubscription,
    required this.availableTypes,
  });
}
