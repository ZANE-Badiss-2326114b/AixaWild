class SubscriptionType {
  final int? id;
  final String name;
  final String? code;
  final String? description;

  SubscriptionType({
    required this.name,
    this.id,
    this.code,
    this.description,
  });

  factory SubscriptionType.fromJson(Map<String, dynamic> json) {
    return SubscriptionType(
      id: _asInt(json['id'] ?? json['subscriptionTypeId']),
      name: _asString(
        json['label'] ?? json['subscriptionTypeLabel'] ?? json['code'] ?? json['subscriptionTypeCode'],
      ),
      code: _asNullableString(json['code'] ?? json['subscriptionTypeCode']),
      description: _asNullableString(json['description'] ?? json['details']),
    );
  }

  static int? _asInt(dynamic value) {
    int? parsedValue;

    if (value is int) {
      parsedValue = value;
    } else {
      if (value is String) {
        parsedValue = int.tryParse(value);
      } else {
        if (value is num) {
          parsedValue = value.toInt();
        } else {
          parsedValue = null;
        }
      }
    }

    return parsedValue;
  }

  static String _asString(dynamic value) {
    String parsedValue;

    final str = value?.toString().trim();
    if (str?.isNotEmpty == true) {
      parsedValue = str!;
    } else {
      parsedValue = 'Type inconnu';
    }

    return parsedValue;
  }

  static String? _asNullableString(dynamic value) {
    String? parsedValue;

    final normalized = value?.toString().trim();
    if (normalized?.isNotEmpty ?? false) {
      parsedValue = normalized;
    } else {
      parsedValue = null;
    }

    return parsedValue;
  }
}
