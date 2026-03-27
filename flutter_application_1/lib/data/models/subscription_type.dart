import '../utils/json_parser.dart';

class SubscriptionType {
	final int? id;
	final String name;
	final String? description;
	final double? price;

	SubscriptionType({
		required this.id,
		required this.name,
		this.description,
		this.price,
	});

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

		return SubscriptionType(
			id: parsedId,
			name: parsedName,
			description: parsedDescription,
			price: parsedPrice,
		);
	}
}
