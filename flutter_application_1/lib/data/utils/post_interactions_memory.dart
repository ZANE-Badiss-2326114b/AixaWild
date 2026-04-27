class PostComment {
  const PostComment({
    required this.authorEmail,
    required this.text,
    required this.createdAt,
  });

  final String authorEmail;
  final String text;
  final DateTime createdAt;
}

class PostInteractionsMemory {
  static final Map<int, List<PostComment>> _commentsByPost = <int, List<PostComment>>{};
  static final Map<String, bool> _likesByUserAndPost = <String, bool>{};

  static String _likeKey(int postId, String userEmail) {
    return '$postId::${userEmail.trim().toLowerCase()}';
  }

  static bool isLikedByUser({required int postId, required String userEmail}) {
    if (userEmail.trim().isEmpty) {
      return false;
    }

    return _likesByUserAndPost[_likeKey(postId, userEmail)] == true;
  }

  static void setLikedByUser({
    required int postId,
    required String userEmail,
    required bool liked,
  }) {
    if (userEmail.trim().isEmpty) {
      return;
    }

    _likesByUserAndPost[_likeKey(postId, userEmail)] = liked;
  }

  static int likesDeltaForPost(int postId) {
    var count = 0;
    final prefix = '$postId::';
    for (final entry in _likesByUserAndPost.entries) {
      if (entry.key.startsWith(prefix) && entry.value) {
        count++;
      }
    }
    return count;
  }

  static List<PostComment> commentsForPost(int postId) {
    final comments = _commentsByPost[postId] ?? <PostComment>[];
    return List<PostComment>.unmodifiable(comments);
  }

  static void addComment({
    required int postId,
    required String authorEmail,
    required String text,
  }) {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      return;
    }

    final comments = _commentsByPost.putIfAbsent(postId, () => <PostComment>[]);
    comments.insert(
      0,
      PostComment(
        authorEmail: authorEmail.trim().isEmpty ? 'Utilisateur' : authorEmail.trim(),
        text: normalizedText,
        createdAt: DateTime.now(),
      ),
    );
  }
}
