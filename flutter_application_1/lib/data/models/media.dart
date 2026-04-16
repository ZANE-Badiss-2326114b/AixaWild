class Media {
	final int id;
	final int postId;
	final String url;
	final String? publicId;
	final String? labelMedia;

	Media({
		required this.id,
		required this.postId,
		required this.url,
		this.publicId,
		this.labelMedia,
	});

	factory Media.fromJson(Map<String, dynamic> json) {
		final idValue = json['id'] ?? json['id_media'];
		final postIdValue = json['postId'] ?? json['post_id'];
		final urlValue = json['secureUrl'] ?? json['secure_url'] ?? json['url'];
		final publicIdValue = json['publicId'] ?? json['public_id'];
		final labelMediaValue = json['labelMedia'] ?? json['label_media'];

		return Media(
			id: idValue is num ? idValue.toInt() : int.tryParse('$idValue') ?? 0,
			postId: postIdValue is num
					? postIdValue.toInt()
					: int.tryParse('$postIdValue') ?? 0,
			url: (urlValue ?? '').toString(),
			publicId: publicIdValue?.toString(),
			labelMedia: labelMediaValue?.toString(),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'postId': postId,
			'url': url,
			'publicId': publicId,
			'labelMedia': labelMedia,
		};
	}
}
