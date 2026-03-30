import '../utils/json_parser.dart';

class User {
  final String email;
  final String username;
  final String? typeName;
  final DateTime? createdAt;

  User({
    required this.email,
    required this.username,
    this.typeName,
    this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final subscription = json['subscription'];
    final subscriptionType = json['subscriptionType'];

    String? parsedTypeName;
    if (subscription is Map<String, dynamic>) {
      parsedTypeName = JsonParser.asString(
        subscription['type_name'] ??
            subscription['typeName'] ??
            subscription['subscriptionTypeLabel'] ??
            subscription['subscriptionTypeCode'],
      );
    }

    if ((parsedTypeName == null || parsedTypeName.isEmpty) &&
        subscriptionType is Map<String, dynamic>) {
      parsedTypeName = JsonParser.asString(
        subscriptionType['type_name'] ??
            subscriptionType['typeName'] ??
            subscriptionType['name'] ??
            subscriptionType['label'],
      );
    }

    final resolvedTypeName = JsonParser.asString(
      json['type_name'] ??
          json['typeName'] ??
          json['subscriptionTypeLabel'] ??
          json['subscriptionTypeCode'] ??
          parsedTypeName,
    );

    return User(
      email: JsonParser.asString(json['user_email'] ?? json['email']),
      username: JsonParser.asString(json['username']),
      typeName: resolvedTypeName.isEmpty ? null : resolvedTypeName,
      createdAt: JsonParser.toDate(json['created_at']),
    );
  }
}