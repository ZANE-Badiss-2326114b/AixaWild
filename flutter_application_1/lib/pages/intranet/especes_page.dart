import 'package:flutter/material.dart';

import '../../data/api/core/dio_client.dart';
import '../../data/models/post.dart';
import '../../data/repositories/opinion_repository.dart';
import '../../data/repositories/post_repository.dart';
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
  late Future<List<Post>> _postsFuture;
  String _userEmail = '';
  bool _isInitialized = false;
  String? _selectedSpecies;

  @override
  void initState() {
    super.initState();
    final apiClient = DioApiClient();
    _postRepository = PostRepository(apiClient);
    _opinionRepository = OpinionRepository(apiClient);
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Espèces'),
      bottomNavigationBar: intranetBottomNavigationBar(context, selectedTab: 'Espèces'),
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
                  const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
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
            final speciesNames = grouped.keys.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

            if (_selectedSpecies == null || !grouped.containsKey(_selectedSpecies)) {
              _selectedSpecies = speciesNames.first;
            }

            final selectedPosts = List<Post>.from(grouped[_selectedSpecies] ?? <Post>[]);
            selectedPosts.sort(_sortNewestFirst);

            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
              children: [
                const Text(
                  'Toutes les espèces',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    mainAxisExtent: 92,
                  ),
                  itemCount: speciesNames.length,
                  itemBuilder: (context, index) {
                    final species = speciesNames[index];
                    final count = grouped[species]!.length;
                    final isSelected = _selectedSpecies == species;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSpecies = species;
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[700] : Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? Colors.blue.shade700 : Colors.blue.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.pets, color: isSelected ? Colors.white : Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    species,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.blue[900],
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$count post(s)',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white70 : Colors.blue[700],
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
                const SizedBox(height: 16),
                Text(
                  'Posts - ${_selectedSpecies ?? ''}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                if (selectedPosts.isEmpty)
                  const Text('Aucun post pour cette espèce.')
                else
                  ...selectedPosts.map((post) => Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                      ),
                                    ),
                                    Text('#${post.id}', style: const TextStyle(color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                if ((post.content ?? '').trim().isNotEmpty) Text(post.content!.trim()),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text(
                                      _formatDate(post.createdAt),
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    const Spacer(),
                                    Text(
                                      post.authorEmail,
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                                        _isPostLiked(post) ? Icons.favorite : Icons.favorite_border,
                                        color: _isPostLiked(post) ? Colors.red : Colors.grey,
                                      ),
                                    ),
                                    Text('${_displayedLikes(post)}'),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      tooltip: 'Commenter',
                                      onPressed: () => _openCommentDialog(post),
                                      icon: const Icon(Icons.mode_comment_outlined),
                                    ),
                                    Text('${PostInteractionsMemory.commentsForPost(post.id).length}'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )),
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
    return posts;
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _loadPosts();
    });
    await _postsFuture;
  }

  Map<String, List<Post>> _groupBySpecies(List<Post> posts) {
    final map = <String, List<Post>>{};

    for (final post in posts) {
      final species = post.title.trim().isEmpty ? 'Sans espèce' : post.title.trim();
      map.putIfAbsent(species, () => <Post>[]).add(post);
    }

    return map;
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

  bool _isPostLiked(Post post) {
    return PostInteractionsMemory.isLikedByUser(postId: post.id, userEmail: _userEmail);
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
        await _opinionRepository.removeLike(postId: post.id, userEmail: _userEmail);
      } else {
        await _opinionRepository.addLike(postId: post.id, userEmail: _userEmail);
      }

      PostInteractionsMemory.setLikedByUser(postId: post.id, userEmail: _userEmail, liked: !currentlyLiked);
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // Keep interaction responsive even when API sync fails.
      PostInteractionsMemory.setLikedByUser(postId: post.id, userEmail: _userEmail, liked: !currentlyLiked);
      if (!mounted) return;
      setState(() {});
      _showMessage('Like enregistre localement, synchronisation API indisponible pour le moment.');
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
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Ecris ton commentaire...'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Publier')),
          ],
        );
      },
    );

    controller.dispose();

    if (text == null || text.trim().isEmpty) {
      return;
    }

    PostInteractionsMemory.addComment(postId: post.id, authorEmail: _userEmail, text: text.trim());
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
                    Expanded(child: Text(post.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                if ((post.content ?? '').trim().isNotEmpty) Text(post.content!.trim()),
                const SizedBox(height: 8),
                Text('Publie le ${_formatDate(post.createdAt)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _toggleLike(post);
                      },
                      icon: Icon(_isPostLiked(post) ? Icons.favorite : Icons.favorite_border),
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
                const Text('Commentaires', style: TextStyle(fontWeight: FontWeight.w700)),
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
                            Text(comment.authorEmail, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(comment.text),
                            const SizedBox(height: 2),
                            Text(_formatDate(comment.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
