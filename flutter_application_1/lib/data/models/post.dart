import 'package:flutter_application_1/data/utils/json_parser.dart';

/// Modèle de domaine post (projection API/Data).
class Post {
  final int id;
  final String authorEmail;
  final String title;
  final String? content;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int likesCount;
  final int reportingCount;
  final DateTime? createdAt;

  /// Construit un post.
  ///
  /// [id] identifiant du post.
  /// [authorEmail] email auteur.
  /// [title] titre.
  /// [content] contenu optionnel.
  /// [locationName] nom de localisation optionnel.
  /// [latitude] latitude optionnelle.
  /// [longitude] longitude optionnelle.
  /// [likesCount] compteur de likes.
  /// [reportingCount] compteur de signalements.
  /// [createdAt] date de création optionnelle.
  Post({required this.id, required this.authorEmail, required this.title, this.content, this.locationName, this.latitude, this.longitude, this.likesCount = 0, this.reportingCount = 0, this.createdAt});

  /// Construit un [Post] depuis un payload JSON hétérogène.
  ///
  /// [json] représente la réponse API source.
  /// Retourne une instance normalisée de [Post].
  factory Post.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['post_id'] ?? json['postId'];
    final likesValue = json['likesCount'] ?? json['likes_count'];
    final reportingValue = json['reportingCount'] ?? json['reporting_count'];
    final locationValue = json['locationName'] ?? json['location_name'] ?? json['location'] ?? json['address'];
    final latitudeValue = json['latitude'] ?? json['lat'];
    final longitudeValue = json['longitude'] ?? json['lng'] ?? json['lon'];

    return Post(id: idValue is num ? idValue.toInt() : int.tryParse('$idValue') ?? 0, authorEmail: JsonParser.asString(json['authorEmail'] ?? json['author_email']), title: JsonParser.asString(json['title']), content: JsonParser.asString(json['content']).isEmpty ? null : JsonParser.asString(json['content']), locationName: JsonParser.asString(locationValue).isEmpty ? null : JsonParser.asString(locationValue), latitude: _toDouble(latitudeValue), longitude: _toDouble(longitudeValue), likesCount: likesValue is num ? likesValue.toInt() : int.tryParse('$likesValue') ?? 0, reportingCount: reportingValue is num ? reportingValue.toInt() : int.tryParse('$reportingValue') ?? 0, createdAt: JsonParser.toDate(json['createdAt'] ?? json['created_at']));
  }

  /// Sérialise le modèle en JSON.
  ///
  /// Retourne une map prête à l'envoi API.
  Map<String, dynamic> toJson() {
    return {'id': id, 'authorEmail': authorEmail, 'title': title, 'content': content, 'locationName': locationName, 'latitude': latitude, 'longitude': longitude, 'likesCount': likesCount, 'reportingCount': reportingCount, 'createdAt': createdAt?.toIso8601String()};
  }

  /// Indique si les coordonnées GPS sont présentes.
  bool get hasLocation => latitude != null && longitude != null;

  /// Convertit une valeur dynamique en `double` nullable.
  ///
  /// [value] est la valeur source.
  /// Retourne un `double` si conversion possible, sinon `null`.
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }
}
