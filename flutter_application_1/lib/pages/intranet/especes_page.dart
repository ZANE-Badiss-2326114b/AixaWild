import 'package:flutter/material.dart';

import '../../data/api/core/dio_client.dart';
import '../../data/models/media.dart';
import '../../data/models/post.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/opinion_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/utils/media_cache.dart';
import '../../data/utils/post_interactions_memory.dart';
import '../../widgets/intranet_appbar.dart';
import '../../widgets/intranet_bottom_navigation.dart';

class EspecesIntranetPage extends StatefulWidget {
  const EspecesIntranetPage({super.key});

  @override
  State<EspecesIntranetPage> createState() => _EspecesIntranetPageState();
}

class _EspecesIntranetPageState extends State<EspecesIntranetPage> {
  late final PostRepository _postRepository;
  late final OpinionRepository _opinionRepository;
  late final MediaRepository _mediaRepository;
  late Future<List<Post>> _postsFuture;
  final TextEditingController _speciesSearchController =
      TextEditingController();
  final MediaCache _mediaCache = MediaCache();
  String _userEmail = '';
  bool _isInitialized = false;
  bool _isSpeciesMenuExpanded = true;
  String? _selectedSpecies;
  String _speciesSearchQuery = '';

  @override
  void initState() {
    super.initState();
    final apiClient = DioApiClient();
    _postRepository = PostRepository(apiClient);
    _opinionRepository = OpinionRepository(apiClient);
    _mediaRepository = MediaRepository(apiClient);
    _postsFuture = _loadPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument is String && routeArgument.trim().isNotEmpty) {
      _userEmail = routeArgument.trim();
    }

    _isInitialized = true;
  }

  @override
  void dispose() {
    _speciesSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Espèces'),
      bottomNavigationBar: intranetBottomNavigationBar(
        context,
        selectedTab: 'Espèces',
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
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
                    'Impossible de charger les espèces.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _postsFuture = _loadPosts();
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
                  Icon(Icons.pets_outlined, size: 40, color: Colors.grey),
                  SizedBox(height: 10),
                  Text(
                    'Aucune espèce disponible pour le moment.',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            final grouped = _groupBySpecies(posts);
            final speciesNames = grouped.keys.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            final normalizedQuery = _normalizeSearchText(_speciesSearchQuery);
            final filteredSpeciesNames = speciesNames.where((species) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return _normalizeSearchText(species).contains(normalizedQuery);
            }).toList();

            if (filteredSpeciesNames.isNotEmpty) {
              if (_selectedSpecies == null ||
                  !filteredSpeciesNames.contains(_selectedSpecies)) {
                _selectedSpecies = filteredSpeciesNames.first;
              }
            } else {
              _selectedSpecies = null;
            }

            final selectedPosts = List<Post>.from(
              grouped[_selectedSpecies] ?? <Post>[],
            );
            selectedPosts.sort(_sortNewestFirst);

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _isSpeciesMenuExpanded = !_isSpeciesMenuExpanded;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade100),
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Toutes les espèces',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_selectedSpecies != null)
                          Flexible(
                            child: Text(
                              _selectedSpecies!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Icon(
                          _isSpeciesMenuExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_isSpeciesMenuExpanded) ...[
                  TextField(
                    controller: _speciesSearchController,
                    onChanged: (value) {
                      setState(() {
                        _speciesSearchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher une catégorie...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _speciesSearchQuery.trim().isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Effacer la recherche',
                              onPressed: () {
                                _speciesSearchController.clear();
                                setState(() {
                                  _speciesSearchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.close),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (filteredSpeciesNames.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: const Text(
                        'Aucune catégorie ne correspond à cette recherche.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            mainAxisExtent: 92,
                          ),
                      itemCount: filteredSpeciesNames.length,
                      itemBuilder: (context, index) {
                        final species = filteredSpeciesNames[index];
                        final count = grouped[species]!.length;
                        final isSelected = _selectedSpecies == species;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSpecies = species;
                              _isSpeciesMenuExpanded = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue[700]
                                  : Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blue.shade700
                                    : Colors.blue.shade100,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.pets,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.blue[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        species,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white
                                              : Colors.blue[900],
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$count post(s)',
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.blue[700],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Posts - ${_selectedSpecies ?? ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (selectedPosts.isEmpty)
                  const Text('Aucun post pour cette espèce.')
                else
                  ...selectedPosts.map(
                    (post) => Card(
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
                              const SizedBox(height: 8),
                              _buildMediaSection(post),
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
                                  Text(
                                    post.authorEmail,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
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
                                    ),
                                  ),
                                  Text('${_displayedLikes(post)}'),
                                  const SizedBox(width: 16),
                                  IconButton(
                                    tooltip: 'Commenter',
                                    onPressed: () => _openCommentDialog(post),
                                    icon: const Icon(
                                      Icons.mode_comment_outlined,
                                    ),
                                  ),
                                  Text(
                                    '${PostInteractionsMemory.commentsForPost(post.id).length}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<List<Post>> _loadPosts() async {
    final posts = await _postRepository.getAllPosts();
    posts.sort(_sortNewestFirst);

    // Charger les médias pour chaque post
    await _loadMediaForPosts(posts);

    return posts;
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

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _loadPosts();
    });
    await _postsFuture;
  }

  Map<String, List<Post>> _groupBySpecies(List<Post> posts) {
    final postsByKey = <String, List<Post>>{};
    final labelsByKey = <String, String>{};

    for (final post in posts) {
      final rawSpecies = post.title.trim().isEmpty
          ? 'Sans espèce'
          : post.title.trim();
      final normalizedKey = _normalizeSearchText(
        rawSpecies,
      ).replaceAll(RegExp(r'\s+'), ' ');
      final displayLabel = _toCategoryLabel(rawSpecies);

      postsByKey.putIfAbsent(normalizedKey, () => <Post>[]).add(post);
      labelsByKey.putIfAbsent(normalizedKey, () => displayLabel);
    }

    final grouped = <String, List<Post>>{};
    for (final entry in postsByKey.entries) {
      final label = labelsByKey[entry.key] ?? _toCategoryLabel(entry.key);
      grouped[label] = entry.value;
    }

    return grouped;
  }

  int _sortNewestFirst(Post a, Post b) {
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
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Date inconnue';
    }

    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _normalizeSearchText(String input) {
    final lower = input.trim().toLowerCase();
    if (lower.isEmpty) {
      return '';
    }

    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'œ': 'oe',
      'æ': 'ae',
    };

    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }

    return buffer.toString();
  }

  String _toCategoryLabel(String input) {
    final normalizedSpace = input.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (normalizedSpace.isEmpty) {
      return 'Sans espèce';
    }

    final words = normalizedSpace.split(' ');
    final titled = words.map((word) {
      final lower = word.toLowerCase();
      if (lower.isEmpty) {
        return lower;
      }
      return '${lower[0].toUpperCase()}${lower.substring(1)}';
    }).toList();

    return titled.join(' ');
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
}
