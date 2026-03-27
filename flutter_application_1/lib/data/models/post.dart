import '../utils/json_parser.dart';

class Post {
	final int id;
	final String authorEmail;
	final String title;
	final String? content;
	final int likesCount;
	final int reportingCount;
	final DateTime? createdAt;

	Post({
		required this.id,
		required this.authorEmail,
		required this.title,
		this.content,
		this.likesCount = 0,
		this.reportingCount = 0,
		this.createdAt,
	});

	factory Post.fromJson(Map<String, dynamic> json) {
		final idValue = json['id'] ?? json['post_id'] ?? json['postId'];
		final likesValue = json['likesCount'] ?? json['likes_count'];
		final reportingValue = json['reportingCount'] ?? json['reporting_count'];

		return Post(
			id: idValue is num ? idValue.toInt() : int.tryParse('$idValue') ?? 0,
			authorEmail: JsonParser.asString(
				json['authorEmail'] ?? json['author_email'],
			),
			title: JsonParser.asString(json['title']),
			content: JsonParser.asString(json['content']).isEmpty
					? null
					: JsonParser.asString(json['content']),
			likesCount: likesValue is num
					? likesValue.toInt()
					: int.tryParse('$likesValue') ?? 0,
			reportingCount: reportingValue is num
					? reportingValue.toInt()
					: int.tryParse('$reportingValue') ?? 0,
			createdAt: JsonParser.toDate(json['createdAt'] ?? json['created_at']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'id': id,
			'authorEmail': authorEmail,
			'title': title,
			'content': content,
			'likesCount': likesCount,
			'reportingCount': reportingCount,
			'createdAt': createdAt?.toIso8601String(),
		};
	}
}
