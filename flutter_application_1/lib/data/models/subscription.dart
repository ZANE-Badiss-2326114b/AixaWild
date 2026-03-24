class Subscription {
  final int? id;
  final String? userEmail;
  final int? subscriptionTypeId;
  final String? subscriptionTypeCode;
  final String? subscriptionTypeLabel;
  final String? status;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool active;

  Subscription({
    this.id,
    this.userEmail,
    this.subscriptionTypeId,
    this.subscriptionTypeCode,
    this.subscriptionTypeLabel,
    this.status,
    this.startedAt,
    this.endedAt,
    required this.active,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    final status = _asNullableString(json['status']);
    final isActive =
        _asBool(json['active']) ?? (status?.toUpperCase().trim() == 'ACTIVE');

    return Subscription(
      id: _asInt(json['id']),
      userEmail: _asNullableString(json['userEmail']),
      subscriptionTypeId: _asInt(json['subscriptionTypeId']),
      subscriptionTypeCode: _asNullableString(json['subscriptionTypeCode']),
      subscriptionTypeLabel: _asNullableString(json['subscriptionTypeLabel']),
      status: status,
      startedAt: _asDate(json['startedAt']),
      endedAt: _asDate(json['endedAt']),
      active: isActive,
    );
  }

  String get currentTypeLabel {
    late final String label;

    if (subscriptionTypeLabel != null && subscriptionTypeLabel!.trim().isNotEmpty) {
      label = subscriptionTypeLabel!;
    } else {
      if (subscriptionTypeCode != null && subscriptionTypeCode!.trim().isNotEmpty) {
        label = subscriptionTypeCode!;
      } else {
        if (subscriptionTypeId != null) {
          label = 'Type #$subscriptionTypeId';
        } else {
          label = 'Aucun type';
        }
      }
    }

    return label;
  }

  DateTime? get startDate => startedAt;
  DateTime? get endDate => endedAt;

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

  static bool? _asBool(dynamic value) {
    bool? parsedValue;

    if (value is bool) {
      parsedValue = value;
    } else {
    if (value is String) {
        if (value.toLowerCase() == 'true') {
          parsedValue = true;
        } else {
          if (value.toLowerCase() == 'false') {
            parsedValue = false;
          } else {
            parsedValue = null;
          }
        }
      } else {
        parsedValue = null;
      }
    }

    return parsedValue;
  }

  static DateTime? _asDate(dynamic value) {
    DateTime? parsedDate;

    if (value == null) {
      parsedDate = null;
    } else {
      if (value is DateTime) {
        parsedDate = value;
      } else {
        if (value is String && value.trim().isNotEmpty) {
          parsedDate = DateTime.tryParse(value.trim());
        } else {
          parsedDate = null;
        }
      }
    }

    return parsedDate;
  }

  static String? _asNullableString(dynamic value) {
    String? parsedValue;

    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      parsedValue = null;
    } else {
      parsedValue = normalized;
    }

    return parsedValue;
  }
}
