import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/models/post.dart';
import '../../data/repositories/opinion_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../widgets/intranet_appbar.dart';

class TestPostsPage extends StatefulWidget {
  const TestPostsPage({super.key});

  @override
  State<TestPostsPage> createState() => _TestPostsPageState();
}

class _TestPostsPageState extends State<TestPostsPage> {
  late final PostRepository _postRepository;
  late final OpinionRepository _opinionRepository;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isInitialized = false;
  bool _isCreatingPost = false;
  int? _likingPostId;
  List<Post> _posts = <Post>[];
  bool _isLoadingPosts = true;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _postRepository = PostRepository(apiClient);
    _opinionRepository = OpinionRepository(apiClient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument is String && routeArgument.trim().isNotEmpty) {
      _emailController.text = routeArgument.trim();
    }

    _isInitialized = true;
    _loadPosts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'Test API Posts & Likes'),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCurrentUserCard(),
            const SizedBox(height: 12),
            _buildCreatePostCard(),
            const SizedBox(height: 12),
            _buildPostsHeader(),
            const SizedBox(height: 8),
            _buildPostsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Utilisateur courant (pour les tests)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email utilisateur',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePostCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Créer un post de test',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Titre',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Contenu',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreatingPost ? null : _createPost,
                icon: _isCreatingPost
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: Text(_isCreatingPost ? 'Création...' : 'Créer post'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Posts API',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          onPressed: _loadPosts,
          icon: const Icon(Icons.refresh),
          tooltip: 'Rafraîchir',
        ),
      ],
    );
  }

  Widget _buildPostsList() {
    if (_isLoadingPosts) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_posts.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Aucun post trouvé.'),
        ),
      );
    }

    final currentEmail = _emailController.text.trim().toLowerCase();

    return Column(
      children: _posts.map((post) {
        final isOwnPost = currentEmail.isNotEmpty &&
            post.authorEmail.trim().toLowerCase() == currentEmail;
        final isLikingCurrent = _likingPostId == post.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(post.content ?? ''),
                const SizedBox(height: 8),
                Text(
                  'Auteur: ${post.authorEmail}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                Text(
                  'Likes: ${post.likesCount}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: isOwnPost || isLikingCurrent
                        ? null
                        : () => _likePost(post.id),
                    icon: isLikingCurrent
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.thumb_up),
                    label: Text(isOwnPost ? 'Votre post' : 'Like'),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final posts = await _postRepository.getAllPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
      });
    } catch (_) {
      if (!mounted) return;
      _showMessage('Erreur lors du chargement des posts.');
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingPosts = false;
      });
    }
  }

  Future<void> _createPost() async {
    final authorEmail = _emailController.text.trim();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (authorEmail.isEmpty || title.isEmpty) {
      _showMessage('Email et titre sont obligatoires.');
      return;
    }

    setState(() {
      _isCreatingPost = true;
    });

    try {
      final created = await _postRepository.createPost(
        authorEmail: authorEmail,
        title: title,
        content: content.isEmpty ? null : content,
      );

      if (created == null) {
        _showMessage('Création du post échouée.');
        return;
      }

      _titleController.clear();
      _contentController.clear();
      _showMessage('Post créé.');
      await _loadPosts();
    } catch (_) {
      _showMessage('Erreur API pendant la création du post.');
    } finally {
      if (!mounted) return;
      setState(() {
        _isCreatingPost = false;
      });
    }
  }

  Future<void> _likePost(int postId) async {
    final userEmail = _emailController.text.trim();
    if (userEmail.isEmpty) {
      _showMessage('Renseigne un email utilisateur pour liker.');
      return;
    }

    setState(() {
      _likingPostId = postId;
    });

    try {
      final opinion = await _opinionRepository.upsertOpinion(
        postId: postId,
        userEmail: userEmail,
        isLike: true,
        labelSignalisation: null,
      );

      if (opinion == null) {
        _showMessage('Like non pris en compte.');
        return;
      }

      _showMessage('Like ajouté.');
      await _loadPosts();
    } catch (_) {
      _showMessage('Erreur API pendant le like.');
    } finally {
      if (!mounted) return;
      setState(() {
        _likingPostId = null;
      });
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
