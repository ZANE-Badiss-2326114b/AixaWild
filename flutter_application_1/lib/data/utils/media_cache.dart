import '../models/media.dart';

class MediaCache {
  static final MediaCache _instance = MediaCache._internal();

  final Map<int, List<Media>> _mediaByPost = <int, List<Media>>{};

  MediaCache._internal();

  factory MediaCache() {
    return _instance;
  }

  /// Récupère les médias pour un post spécifique
  List<Media> getMediaForPost(int postId) {
    return _mediaByPost[postId] ?? <Media>[];
  }

  /// Ajoute ou remplace les médias d'un post
  void setMediaForPost(int postId, List<Media> media) {
    _mediaByPost[postId] = media;
  }

  /// Ajoute des médias supplémentaires à un post
  void addMediaForPost(int postId, List<Media> media) {
    if (_mediaByPost.containsKey(postId)) {
      _mediaByPost[postId]!.addAll(media);
    } else {
      _mediaByPost[postId] = media;
    }
  }

  /// Vérifie si un post a des médias en cache
  bool hasMediaForPost(int postId) {
    return _mediaByPost.containsKey(postId) && _mediaByPost[postId]!.isNotEmpty;
  }

  /// Vide le cache complètement
  void clear() {
    _mediaByPost.clear();
  }

  /// Vide les médias d'un post spécifique
  void clearMediaForPost(int postId) {
    _mediaByPost.remove(postId);
  }

  /// Récupère tous les médias en cache
  Map<int, List<Media>> getAllMedia() {
    return Map.from(_mediaByPost);
  }
}
