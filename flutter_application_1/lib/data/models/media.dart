/// Modèle de domaine média (image/vidéo) associé à un post.
class Media {
  final int id;
  final int postId;
  final String url;
  final String? publicId;
  final String? labelMedia;

  /// Construit un média.
  ///
  /// [id] identifiant du média.
  /// [postId] identifiant du post parent.
  /// [url] URL de consultation du média.
  /// [publicId] identifiant distant de stockage éventuel.
  /// [labelMedia] type logique (image/video/audio) éventuel.
  Media({required this.id, required this.postId, required this.url, this.publicId, this.labelMedia});

  /// Construit un [Media] depuis un payload JSON hétérogène.
  ///
  /// [json] représente la réponse API source.
  /// Retourne une instance normalisée de [Media].
  factory Media.fromJson(Map<String, dynamic> json) {
    final idValue = json['id'] ?? json['id_media'];
    final postIdValue = json['postId'] ?? json['post_id'];
    final urlValue = json['secureUrl'] ?? json['secure_url'] ?? json['url'];
    final publicIdValue = json['publicId'] ?? json['public_id'];
    final labelMediaValue = json['labelMedia'] ?? json['label_media'];

    return Media(id: idValue is num ? idValue.toInt() : int.tryParse('$idValue') ?? 0, postId: postIdValue is num ? postIdValue.toInt() : int.tryParse('$postIdValue') ?? 0, url: (urlValue ?? '').toString(), publicId: publicIdValue?.toString(), labelMedia: labelMediaValue?.toString());
  }

  /// Sérialise le modèle en JSON.
  ///
  /// Retourne une map prête à l'envoi API.
  Map<String, dynamic> toJson() {
    return {'id': id, 'postId': postId, 'url': url, 'publicId': publicId, 'labelMedia': labelMedia};
  }
}
