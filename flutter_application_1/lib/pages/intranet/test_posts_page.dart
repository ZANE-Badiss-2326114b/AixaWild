import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/api/api_client.dart';
import '../../data/models/media.dart';
import '../../data/models/post.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../widgets/intranet_appbar.dart';

class TestPostsPage extends StatefulWidget {
  const TestPostsPage({super.key});

  @override
  State<TestPostsPage> createState() => _TestPostsPageState();
}

class _TestPostsPageState extends State<TestPostsPage> {
  late final PostRepository _postRepository;
  late final MediaRepository _mediaRepository;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _createPostImage;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isInitialized = false;
  bool _isCreatingPost = false;
  List<Post> _posts = <Post>[];
  final Map<int, List<Media>> _mediaByPost = <int, List<Media>>{};
  final Map<int, bool> _isUploadingByPost = <int, bool>{};
  bool _isLoadingPosts = true;

  String get _currentEmail => _emailController.text.trim();

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _postRepository = PostRepository(apiClient);
    _mediaRepository = MediaRepository(apiClient);
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
            OutlinedButton.icon(
              onPressed: _isCreatingPost ? null : _pickImageForCreatePost,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_createPostImage == null ? 'Ajouter une image (optionnel)' : 'Changer l\'image'),
            ),
            if (_createPostImage != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_createPostImage!.path),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isCreatingPost
                      ? null
                      : () {
                          setState(() {
                            _createPostImage = null;
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Retirer l\'image'),
                ),
              ),
            ],
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
                    _buildMediaSection(post),
                    const SizedBox(height: 8),
                    if (isOwnPost)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Align(
                            alignment: Alignment.centerRight,
                            child: Chip(label: Text('Votre post')),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUploadingByPost[post.id] == true ? null : () => _pickAndUploadImage(post.id),
                              icon: _isUploadingByPost[post.id] == true
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.image),
                              label: Text(_isUploadingByPost[post.id] == true ? 'Upload en cours...' : 'Ajouter une image depuis la galerie'),
                            ),
                          ),
                        ],
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
      await _loadMediaForPosts(posts);
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

  Future<void> _loadMediaForPosts(List<Post> posts) async {
    final loadedMedia = <int, List<Media>>{};

    for (final post in posts) {
      try {
        final media = await _mediaRepository.getByPostId(post.id);
        loadedMedia[post.id] = media;
      } catch (_) {
        loadedMedia[post.id] = <Media>[];
      }
    }

    if (mounted) {
      setState(() {
        _mediaByPost
          ..clear()
          ..addAll(loadedMedia);
      });
    }
  }

  Future<void> _pickAndUploadImage(int postId) async {
    final selectedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (selectedImage == null) {
      return;
    }

    setState(() {
      _isUploadingByPost[postId] = true;
    });

    try {
      final media = await _mediaRepository.uploadMedia(postId: postId, imageFile: File(selectedImage.path));

      if (media == null) {
        _showMessage('Upload échoué.');
      } else {
        if (mounted) {
          final currentList = List<Media>.from(_mediaByPost[postId] ?? <Media>[]);
          currentList.insert(0, media);
          setState(() {
            _mediaByPost[postId] = currentList;
          });
        }
        _showMessage('Image uploadée avec succès.');
      }
    } catch (error) {
      _showMessage('Erreur API pendant l\'upload: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingByPost[postId] = false;
        });
      }
    }
  }

  Widget _buildMediaSection(Post post) {
    final mediaList = _mediaByPost[post.id] ?? <Media>[];

    if (mediaList.isEmpty) {
      return const Text('Aucune image associée.', style: TextStyle(fontSize: 12, color: Colors.black54));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mediaList.map((media) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              media.url,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text('Impossible de charger l\'image.'),
                );
              },
            ),
          ),
        );
      }).toList(),
    );
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
          final selectedImage = _createPostImage;
          Media? uploadedMedia;
          var uploadFailed = false;

          if (selectedImage != null) {
            try {
              uploadedMedia = await _mediaRepository.uploadMedia(postId: created.id, imageFile: File(selectedImage.path));
            } catch (_) {
              uploadFailed = true;
            }
          }

          if (mounted) {
            setState(() {
              _posts = <Post>[created, ..._posts.where((post) => post.id != created.id)];
              if (uploadedMedia != null) {
                _mediaByPost[created.id] = <Media>[uploadedMedia];
              }
            });
          }

          await _loadMediaForPost(created.id);

          _titleController.clear();
          _contentController.clear();
          if (mounted) {
            setState(() {
              _createPostImage = null;
            });
          }

          if (selectedImage != null) {
            if (uploadFailed) {
              _showMessage('Post créé, mais échec de l\'upload de l\'image.');
            } else {
              _showMessage('Post et image créés avec succès.');
            }
          } else {
            _showMessage('Post créé avec succès.');
          }

          await _loadPosts();
        }
      } catch (error) {
        _showMessage('Erreur API pendant la création: $error');
      } finally {
        if (mounted) {
          setState(() {
            _isCreatingPost = false;
          });
        }
      }
    }
  }

  Future<void> _pickImageForCreatePost() async {
    final selectedImage = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (selectedImage == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _createPostImage = selectedImage;
      });
    }
  }

  Future<void> _loadMediaForPost(int postId) async {
    try {
      final media = await _mediaRepository.getByPostId(postId);
      if (mounted) {
        setState(() {
          _mediaByPost[postId] = media;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _mediaByPost[postId] = <Media>[];
        });
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
