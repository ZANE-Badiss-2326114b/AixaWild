class Media {
	final int id;
	final int postId;
	final String url;

	Media({
		required this.id,
		required this.postId,
		required this.url,
	});

	factory Media.fromJson(Map<String, dynamic> json) {
		final idValue = json['id'] ?? json['id_media'];
		final postIdValue = json['postId'] ?? json['post_id'];

		return Media(
			id: idValue is num ? idValue.toInt() : int.tryParse('$idValue') ?? 0,
			postId: postIdValue is num
					? postIdValue.toInt()
					: int.tryParse('$postIdValue') ?? 0,
			url: (json['url'] ?? '').toString(),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'postId': postId,
			'url': url,
		};
	}
}
