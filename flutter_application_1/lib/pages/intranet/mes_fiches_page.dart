import 'package:flutter/material.dart';

import '../../data/api/core/dio_client.dart';
import '../../data/models/media.dart';
import '../../data/models/post.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/opinion_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/utils/media_cache.dart';
import '../../data/utils/post_interactions_memory.dart';
import '../../widgets/intranet_bottom_navigation.dart';
import '../../widgets/intranet_appbar.dart';

class MesFichesIntranetPage extends StatefulWidget {
  const MesFichesIntranetPage({super.key});

  @override
  State<MesFichesIntranetPage> createState() => _MesFichesIntranetPageState();
}

class _MesFichesIntranetPageState extends State<MesFichesIntranetPage> {
  late final PostRepository _postRepository;
  late final OpinionRepository _opinionRepository;
  late final MediaRepository _mediaRepository;
  late Future<List<Post>> _userPostsFuture;
  final MediaCache _mediaCache = MediaCache();
  String _userEmail = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    final apiClient = DioApiClient();
    _postRepository = PostRepository(apiClient);
    _opinionRepository = OpinionRepository(apiClient);
    _mediaRepository = MediaRepository(apiClient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      return;
    }

    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument is String && routeArgument.trim().isNotEmpty) {
      _userEmail = routeArgument.trim();
    }

    _userPostsFuture = _loadUserPosts();
    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Mes fiches'),
      body: RefreshIndicator(onRefresh: _refreshPosts, child: _buildBody()),
      bottomNavigationBar: intranetBottomNavigationBar(
        context,
        selectedTab: 'Mes fiches',
      ),
    );
  }

  Widget _buildBody() {
    if (_userEmail.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          SizedBox(height: 80),
          Icon(Icons.info_outline, size: 40, color: Colors.grey),
          SizedBox(height: 10),
          Text(
            'Email utilisateur manquant. Retourne à l\'accueil connecté puis ouvre Mes fiches.',
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return FutureBuilder<List<Post>>(
      future: _userPostsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView(
            children: const [
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator()),
            ],
          );
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 80),
              const Icon(
                Icons.error_outline,
                size: 40,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 10),
              const Text(
                'Impossible de charger tes posts pour le moment.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _userPostsFuture = _loadUserPosts();
                    });
                  },
                  child: const Text('Réessayer'),
                ),
              ),
            ],
          );
        }

        final posts = snapshot.data ?? <Post>[];
        if (posts.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              SizedBox(height: 80),
              Icon(Icons.post_add_outlined, size: 40, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'Tu n\'as pas encore publié de fiche.',
                textAlign: TextAlign.center,
              ),
            ],
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
          itemCount: posts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final post = posts[index];
            return Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openPostDetails(post),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              post.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            '#${post.id}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      if ((post.content ?? '').trim().isNotEmpty)
                        Text(post.content!.trim()),
                      if ((post.locationName ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                post.locationName!.trim(),
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildMediaSection(post),
                      if (_mediaCache.hasMediaForPost(post.id))
                        const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatDate(post.createdAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Like',
                            onPressed: () => _toggleLike(post),
                            icon: Icon(
                              _isPostLiked(post)
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isPostLiked(post)
                                  ? Colors.red
                                  : Colors.grey,
                              size: 18,
                            ),
                          ),
                          Text(
                            '${_displayedLikes(post)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Commenter',
                            onPressed: () => _openCommentDialog(post),
                            icon: const Icon(
                              Icons.mode_comment_outlined,
                              size: 18,
                            ),
                          ),
                          Text(
                            '${PostInteractionsMemory.commentsForPost(post.id).length}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<List<Post>> _loadUserPosts() async {
    final allPosts = await _postRepository.getAllPosts();
    final normalizedEmail = _userEmail.trim().toLowerCase();

    final userPosts = allPosts.where((post) {
      return post.authorEmail.trim().toLowerCase() == normalizedEmail;
    }).toList();

    userPosts.sort((a, b) {
      final dateA = a.createdAt;
      final dateB = b.createdAt;

      if (dateA == null && dateB == null) {
        return b.id.compareTo(a.id);
      }
      if (dateA == null) {
        return 1;
      }
      if (dateB == null) {
        return -1;
      }

      final byDate = dateB.compareTo(dateA);
      if (byDate != 0) {
        return byDate;
      }

      return b.id.compareTo(a.id);
    });

    await _loadMediaForPosts(userPosts);
    return userPosts;
  }

  Future<void> _loadMediaForPosts(List<Post> posts) async {
    for (final post in posts) {
      if (!_mediaCache.hasMediaForPost(post.id)) {
        try {
          final media = await _mediaRepository.getByPostId(post.id);
          _mediaCache.setMediaForPost(post.id, media);
        } catch (_) {
          _mediaCache.setMediaForPost(post.id, <Media>[]);
        }
      }
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _userPostsFuture = _loadUserPosts();
    });
    await _userPostsFuture;
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Date inconnue';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  bool _isPostLiked(Post post) {
    return PostInteractionsMemory.isLikedByUser(
      postId: post.id,
      userEmail: _userEmail,
    );
  }

  int _displayedLikes(Post post) {
    return post.likesCount + PostInteractionsMemory.likesDeltaForPost(post.id);
  }

  Future<void> _toggleLike(Post post) async {
    if (_userEmail.trim().isEmpty) {
      _showMessage('Email utilisateur manquant.');
      return;
    }

    final currentlyLiked = _isPostLiked(post);

    try {
      if (currentlyLiked) {
        await _opinionRepository.removeLike(
          postId: post.id,
          userEmail: _userEmail,
        );
      } else {
        await _opinionRepository.addLike(
          postId: post.id,
          userEmail: _userEmail,
        );
      }

      PostInteractionsMemory.setLikedByUser(
        postId: post.id,
        userEmail: _userEmail,
        liked: !currentlyLiked,
      );
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // Keep interaction responsive even when API sync fails.
      PostInteractionsMemory.setLikedByUser(
        postId: post.id,
        userEmail: _userEmail,
        liked: !currentlyLiked,
      );
      if (!mounted) return;
      setState(() {});
      _showMessage(
        'Like enregistre localement, synchronisation API indisponible pour le moment.',
      );
    }
  }

  Future<void> _openCommentDialog(Post post) async {
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ajouter un commentaire'),
          content: TextField(
            controller: controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Ecris ton commentaire...',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Publier'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (text == null || text.trim().isEmpty) {
      return;
    }

    PostInteractionsMemory.addComment(
      postId: post.id,
      authorEmail: _userEmail,
      text: text.trim(),
    );
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openPostDetails(Post post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final comments = PostInteractionsMemory.commentsForPost(post.id);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        post.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                if ((post.content ?? '').trim().isNotEmpty)
                  Text(post.content!.trim()),
                const SizedBox(height: 8),
                Text(
                  'Publie le ${_formatDate(post.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _toggleLike(post);
                      },
                      icon: Icon(
                        _isPostLiked(post)
                            ? Icons.favorite
                            : Icons.favorite_border,
                      ),
                      label: Text('Like (${_displayedLikes(post)})'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _openCommentDialog(post);
                      },
                      icon: const Icon(Icons.mode_comment_outlined),
                      label: Text('Commenter (${comments.length})'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Commentaires',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (comments.isEmpty)
                  const Text('Aucun commentaire pour le moment.')
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: comments.length,
                      separatorBuilder: (_, _) => const Divider(height: 12),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.authorEmail,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(comment.text),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(comment.createdAt),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildMediaSection(Post post) {
    final mediaList = _mediaCache.getMediaForPost(post.id);

    if (mediaList.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mediaList.map((media) {
        final isVideo = _isVideoUrl(media.url);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: isVideo
              ? Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[300],
                  ),
                  child: const Center(child: Icon(Icons.videocam, size: 40)),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    media.url,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
                      return Container(
                        height: 180,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      );
                    },
                  ),
                ),
        );
      }).toList(),
    );
  }

  bool _isVideoUrl(String url) {
    final normalizedPath =
        Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return normalizedPath.endsWith('.mp4') ||
        normalizedPath.endsWith('.mov') ||
        normalizedPath.endsWith('.webm') ||
        normalizedPath.endsWith('.m4v') ||
        normalizedPath.endsWith('.avi') ||
        normalizedPath.endsWith('.mkv');
  }
}
