import 'package:flutter/foundation.dart';

import 'package:flutter_application_1/data/models/opinion.dart';
import 'package:flutter_application_1/data/models/post.dart';
import 'package:flutter_application_1/data/repositories/opinion_repository.dart';
import 'package:flutter_application_1/data/repositories/post_repository.dart';

class PostEngagementStats {
  const PostEngagementStats({required this.likes, required this.reports});

  final int likes;
  final int reports;
}

class AdminPostMonitoringProvider extends ChangeNotifier {
  AdminPostMonitoringProvider({
    required PostRepository postRepository,
    required OpinionRepository opinionRepository,
  })  : _postRepository = postRepository,
        _opinionRepository = opinionRepository;

  final PostRepository _postRepository;
  final OpinionRepository _opinionRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<Post> _posts = <Post>[];
  List<Post> get posts => List<Post>.unmodifiable(_posts);

  Map<int, PostEngagementStats> _statsByPost = <int, PostEngagementStats>{};
  Map<int, PostEngagementStats> get statsByPost => Map<int, PostEngagementStats>.unmodifiable(_statsByPost);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final loadedPosts = await _postRepository.getAllPosts();
      _posts = loadedPosts;

      List<Opinion> opinions;
      try {
        opinions = await _opinionRepository.getAllOpinions();
      } catch (_) {
        opinions = <Opinion>[];
      }

      final likesByPost = <int, int>{};
      final reportsByPost = <int, int>{};

      for (final opinion in opinions) {
        final postId = opinion.postId;

        if (opinion.isLike == true) {
          likesByPost[postId] = (likesByPost[postId] ?? 0) + 1;
        }

        final signal = opinion.labelSignalisation?.trim();
        if (signal != null && signal.isNotEmpty) {
          reportsByPost[postId] = (reportsByPost[postId] ?? 0) + 1;
        }
      }

      final computedStats = <int, PostEngagementStats>{};
      for (final post in loadedPosts) {
        final hasOpinionStats = likesByPost.containsKey(post.id) || reportsByPost.containsKey(post.id);

        if (hasOpinionStats) {
          computedStats[post.id] = PostEngagementStats(
            likes: likesByPost[post.id] ?? 0,
            reports: reportsByPost[post.id] ?? 0,
          );
        } else {
          computedStats[post.id] = PostEngagementStats(
            likes: post.likesCount,
            reports: post.reportingCount,
          );
        }
      }

      _statsByPost = computedStats;
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deletePost(int postId) async {
    bool isSuccess;

    _errorMessage = null;
    notifyListeners();

    try {
      await _postRepository.deletePost(postId);
      await loadPosts();
      isSuccess = true;
    } catch (error) {
      _errorMessage = error.toString();
      isSuccess = false;
    }

    notifyListeners();
    return isSuccess;
  }
}
