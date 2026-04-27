import 'package:flutter_application_1/data/utils/json_parser.dart';

/// Modèle de domaine opinion (like/signalement).
class Opinion {
  final String userEmail;
  final int postId;
  final bool? isLike;
  final String? labelSignalisation;

  /// Construit une opinion.
  ///
  /// [userEmail] identifie l'utilisateur auteur.
  /// [postId] identifie le post concerné.
  /// [isLike] indique l'état de like éventuel.
  /// [labelSignalisation] porte un motif de signalement éventuel.
  Opinion({required this.userEmail, required this.postId, this.isLike, this.labelSignalisation});

  /// Construit une [Opinion] depuis un payload JSON hétérogène.
  ///
  /// [json] représente la réponse API source.
  /// Retourne une instance normalisée de [Opinion].
  factory Opinion.fromJson(Map<String, dynamic> json) {
    final postIdValue = json['postId'] ?? json['post_id'];
    final labelValue = JsonParser.asString(json['labelSignalisation'] ?? json['label_signalisation']);

    return Opinion(userEmail: JsonParser.asString(json['userEmail'] ?? json['user_email']), postId: postIdValue is num ? postIdValue.toInt() : int.tryParse('$postIdValue') ?? 0, isLike: json['isLike'] ?? json['is_like'] as bool?, labelSignalisation: labelValue.isEmpty ? null : labelValue);
  }

  /// Sérialise le modèle en JSON.
  ///
  /// Retourne une map prête à l'envoi API.
  Map<String, dynamic> toJson() {
    return {'userEmail': userEmail, 'postId': postId, 'isLike': isLike, 'labelSignalisation': labelSignalisation};
  }
}
