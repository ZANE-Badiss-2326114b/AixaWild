import '../utils/json_parser.dart';

class Opinion {
	final String userEmail;
	final int postId;
	final bool? isLike;
	final String? labelSignalisation;

	Opinion({
		required this.userEmail,
		required this.postId,
		this.isLike,
		this.labelSignalisation,
	});

	factory Opinion.fromJson(Map<String, dynamic> json) {
		final postIdValue = json['postId'] ?? json['post_id'];
		final labelValue = JsonParser.asString(
			json['labelSignalisation'] ?? json['label_signalisation'],
		);

		return Opinion(
			userEmail: JsonParser.asString(json['userEmail'] ?? json['user_email']),
			postId: postIdValue is num
					? postIdValue.toInt()
					: int.tryParse('$postIdValue') ?? 0,
			isLike: json['isLike'] ?? json['is_like'] as bool?,
			labelSignalisation: labelValue.isEmpty ? null : labelValue,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'userEmail': userEmail,
			'postId': postId,
			'isLike': isLike,
			'labelSignalisation': labelSignalisation,
		};
	}
}
