import 'package:flutter_application_1/data/utils/json_parser.dart';

/// Modèle de domaine d'un type d'abonnement.
class SubscriptionType {
  final int? id;
  final String name;
  final String? description;
  final double? price;

  /// Construit un type d'abonnement.
  ///
  /// [id] identifiant éventuel.
  /// [name] libellé du type.
  /// [description] description éventuelle.
  /// [price] prix éventuel.
  SubscriptionType({required this.id, required this.name, this.description, this.price});

  /// Construit un [SubscriptionType] depuis un payload JSON hétérogène.
  ///
  /// [json] représente la réponse API source.
  /// Retourne une instance normalisée de [SubscriptionType].
  factory SubscriptionType.fromJson(Map<String, dynamic> json) {
    int? parsedId;
    final rawId = json['id'] ?? json['type_id'];

    if (rawId != null) {
      if (rawId is int) {
        parsedId = rawId;
      } else {
        parsedId = int.tryParse(rawId.toString());
      }
    } else {
      parsedId = null;
    }

    String parsedName;
    final nameValue = json['name'] ?? json['type_name'] ?? json['label'];
    final normalizedName = JsonParser.asString(nameValue);
    if (normalizedName.isNotEmpty) {
      parsedName = normalizedName;
    } else {
      parsedName = 'Free';
    }

    String? parsedDescription;
    final descriptionValue = json['description'] ?? json['type_description'];
    final normalizedDescription = JsonParser.asString(descriptionValue);
    if (normalizedDescription.isNotEmpty) {
      parsedDescription = normalizedDescription;
    } else {
      parsedDescription = null;
    }

    double? parsedPrice;
    final priceValue = json['price'];
    if (priceValue != null) {
      if (priceValue is num) {
        parsedPrice = priceValue.toDouble();
      } else {
        parsedPrice = double.tryParse(priceValue.toString());
      }
    } else {
      parsedPrice = null;
    }

    return SubscriptionType(id: parsedId, name: parsedName, description: parsedDescription, price: parsedPrice);
  }
}
