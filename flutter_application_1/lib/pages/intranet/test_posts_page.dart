import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../../widgets/intranet_appbar.dart';

class TestPostsPage extends StatefulWidget {
  const TestPostsPage({super.key});

  @override
  State<TestPostsPage> createState() => _TestPostsPageState();
}

class _TestPostsPageState extends State<TestPostsPage> {
  late final PostRepository _postRepository;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isInitialized = false;
  bool _isCreatingPost = false;
  List<Post> _posts = <Post>[];
  bool _isLoadingPosts = true;

  String get _currentEmail => _emailController.text.trim();

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _postRepository = PostRepository(apiClient);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final routeArgument = ModalRoute.of(context)?.settings.arguments;
      if (routeArgument is String && routeArgument.trim().isNotEmpty) {
        _emailController.text = routeArgument.trim();
      }

      _isInitialized = true;
      _loadPosts();
    }
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
      appBar: intranetAppBar(title: 'Exemple API - Posts'),
      body: RefreshIndicator(
        onRefresh: _loadPosts,
        child: ListView(padding: const EdgeInsets.all(16), children: [_buildCurrentUserCard(), const SizedBox(height: 12), _buildCreatePostCard(), const SizedBox(height: 12), _buildPostsHeader(), const SizedBox(height: 8), _buildPostsList()]),
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
            const Text('1) Utilisateur courant', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Email', hintText: 'exemple@domaine.com'),
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
            const Text('2) Créer un post', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Titre'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Contenu'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreatingPost ? null : _createPost,
                icon: _isCreatingPost ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
                label: Text(_isCreatingPost ? 'Création...' : 'Créer le post'),
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
        const Text('3) Liste des posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(onPressed: _loadPosts, icon: const Icon(Icons.refresh), tooltip: 'Rafraîchir'),
      ],
    );
  }

  Widget _buildPostsList() {
    Widget result;

    if (_isLoadingPosts) {
      result = const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    } else {
      if (_posts.isEmpty) {
        result = const Card(
          child: Padding(padding: EdgeInsets.all(16), child: Text('Aucun post pour le moment.')),
        );
      } else {
        final currentEmail = _currentEmail.toLowerCase();
        result = Column(
          children: _posts.map((post) {
            final isOwnPost = currentEmail.isNotEmpty && post.authorEmail.trim().toLowerCase() == currentEmail;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(post.content ?? ''),
                    const SizedBox(height: 8),
                    Text('Auteur: ${post.authorEmail}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    Text('Likes: ${post.likesCount}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 8),
                    if (isOwnPost)
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Chip(label: Text('Votre post')),
                      )
                    else
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Chip(label: Text('Autre utilisateur')),
                      ),
                    Text('ID post: ${post.id}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      }
    }

    return result;
  }

  Future<void> _loadPosts() async {
    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final posts = await _postRepository.getAllPosts();
      if (mounted) {
        setState(() {
          _posts = posts;
        });
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Erreur lors du chargement des posts.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _createPost() async {
    final authorEmail = _currentEmail;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (authorEmail.isEmpty || title.isEmpty) {
      _showMessage('Email et titre sont obligatoires.');
    } else {
      setState(() {
        _isCreatingPost = true;
      });

      try {
        final created = await _postRepository.createPost(authorEmail: authorEmail, title: title, content: content.isEmpty ? null : content);

        if (created == null) {
          _showMessage('Création échouée.');
        } else {
          _titleController.clear();
          _contentController.clear();
          _showMessage('Post créé avec succès.');
          await _loadPosts();
        }
      } catch (_) {
        _showMessage('Erreur API pendant la création.');
      } finally {
        if (mounted) {
          setState(() {
            _isCreatingPost = false;
          });
        }
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
