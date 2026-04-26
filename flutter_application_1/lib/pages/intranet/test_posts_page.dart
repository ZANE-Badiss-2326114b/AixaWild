import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../../data/api/core/dio_client.dart';
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
  List<XFile> _createPostImages = <XFile>[];
  XFile? _createPostVideo;
  static const Duration _maxVideoDuration = Duration(seconds: 21);

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
    final apiClient = DioApiClient();
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
              onPressed: _isCreatingPost ? null : _pickImagesForCreatePost,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_createPostImages.isEmpty ? 'Ajouter des images (optionnel)' : '${_createPostImages.length} image(s) sélectionnée(s)'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isCreatingPost ? null : _pickVideoForCreatePost,
              icon: const Icon(Icons.videocam_outlined),
              label: Text(_createPostVideo == null ? 'Ajouter une vidéo (max 21s)' : 'Vidéo sélectionnée (max 21s)'),
            ),
            if (_createPostImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _createPostImages.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final image = _createPostImages[index];
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(image.path),
                            height: 110,
                            width: 110,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _isCreatingPost
                                ? null
                                : () {
                                    setState(() {
                                      _createPostImages.removeAt(index);
                                    });
                                  },
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isCreatingPost
                      ? null
                      : () {
                          setState(() {
                            _createPostImages = <XFile>[];
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Retirer toutes les images'),
                ),
              ),
            ],
            if (_createPostVideo != null) ...[
              const SizedBox(height: 8),
              _LocalVideoPreview(videoFile: File(_createPostVideo!.path)),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _isCreatingPost
                      ? null
                      : () {
                          setState(() {
                            _createPostVideo = null;
                          });
                        },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Retirer la vidéo'),
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
                              onPressed: _isUploadingByPost[post.id] == true ? null : () => _pickAndUploadImages(post.id),
                              icon: _isUploadingByPost[post.id] == true
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.image),
                              label: Text(_isUploadingByPost[post.id] == true ? 'Upload en cours...' : 'Ajouter des images depuis la galerie'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUploadingByPost[post.id] == true ? null : () => _pickAndUploadVideo(post.id),
                              icon: _isUploadingByPost[post.id] == true
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.videocam),
                              label: Text(_isUploadingByPost[post.id] == true ? 'Upload en cours...' : 'Ajouter une vidéo (max 21s)'),
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

  Future<void> _pickAndUploadImages(int postId) async {
    final selectedImages = await _imagePicker.pickMultiImage();
    if (selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _isUploadingByPost[postId] = true;
    });

    try {
      final uploadedMedia = <Media>[];
      for (final selectedImage in selectedImages) {
        final media = await _uploadPickedFile(postId: postId, file: selectedImage);
        if (media != null) {
          uploadedMedia.add(media);
        }
      }

      if (uploadedMedia.isEmpty) {
        _showMessage('Upload échoué.');
      } else {
        if (mounted) {
          final currentList = List<Media>.from(_mediaByPost[postId] ?? <Media>[]);
          _mediaByPost[postId] = <Media>[...uploadedMedia, ...currentList];
          setState(() {});
        }
        _showMessage('${uploadedMedia.length} image(s) uploadée(s) avec succès.');
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
      return const Text('Aucune image/vidéo associée.', style: TextStyle(fontSize: 12, color: Colors.black54));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mediaList.map((media) {
        final isVideo = _isVideoUrl(media.url);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: isVideo
              ? _NetworkVideoPlayer(url: media.url)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    media.url,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) {
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
          final selectedImages = List<XFile>.from(_createPostImages);
          final selectedVideo = _createPostVideo;
          var uploadedCount = 0;
          var uploadFailed = false;

          for (final selectedImage in selectedImages) {
            try {
              final uploadedMedia = await _uploadPickedFile(postId: created.id, file: selectedImage);
              if (uploadedMedia != null) {
                uploadedCount++;
              } else {
                uploadFailed = true;
              }
            } catch (_) {
              uploadFailed = true;
            }
          }

          if (selectedVideo != null) {
            try {
              final uploadedMedia = await _uploadPickedFile(postId: created.id, file: selectedVideo);
              if (uploadedMedia != null) {
                uploadedCount++;
              } else {
                uploadFailed = true;
              }
            } catch (_) {
              uploadFailed = true;
            }
          }

          if (mounted) {
            setState(() {
              _posts = <Post>[created, ..._posts.where((post) => post.id != created.id)];
            });
          }

          await _loadMediaForPost(created.id);

          _titleController.clear();
          _contentController.clear();
          if (mounted) {
            setState(() {
              _createPostImages = <XFile>[];
              _createPostVideo = null;
            });
          }

          if (selectedImages.isNotEmpty || selectedVideo != null) {
            if (uploadFailed) {
              _showMessage('Post créé, mais l\'upload de certains médias a échoué.');
            } else {
              _showMessage('Post et $uploadedCount média(s) créés avec succès.');
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

  Future<void> _pickImagesForCreatePost() async {
    final selectedImages = await _imagePicker.pickMultiImage();
    if (selectedImages.isEmpty) {
      return;
    }

    if (mounted) {
      setState(() {
        _createPostImages = <XFile>[..._createPostImages, ...selectedImages];
      });
    }
  }

  Future<void> _pickVideoForCreatePost() async {
    final selectedVideo = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: _maxVideoDuration,
    );

    if (selectedVideo == null) {
      return;
    }

    final isValidDuration = await _isVideoWithinMaxDuration(File(selectedVideo.path));
    if (!isValidDuration) {
      _showMessage('La vidéo doit durer 21 secondes maximum.');
      return;
    }

    if (mounted) {
      setState(() {
        _createPostVideo = selectedVideo;
      });
    }
  }

  Future<void> _pickAndUploadVideo(int postId) async {
    final selectedVideo = await _imagePicker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: _maxVideoDuration,
    );
    if (selectedVideo == null) {
      return;
    }

    final isValidDuration = await _isVideoWithinMaxDuration(File(selectedVideo.path));
    if (!isValidDuration) {
      _showMessage('La vidéo doit durer 21 secondes maximum.');
      return;
    }

    setState(() {
      _isUploadingByPost[postId] = true;
    });

    try {
      final media = await _uploadPickedFile(postId: postId, file: selectedVideo);

      if (media == null) {
        _showMessage('Upload vidéo échoué.');
      } else {
        if (mounted) {
          final currentList = List<Media>.from(_mediaByPost[postId] ?? <Media>[]);
          _mediaByPost[postId] = <Media>[media, ...currentList];
          setState(() {});
        }
        _showMessage('Vidéo uploadée avec succès.');
      }
    } catch (error) {
      _showMessage('Erreur API pendant l\'upload vidéo: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingByPost[postId] = false;
        });
      }
    }
  }

  Future<bool> _isVideoWithinMaxDuration(File videoFile) async {
    final controller = VideoPlayerController.file(videoFile);
    try {
      await controller.initialize();
      final duration = controller.value.duration;
      return duration <= _maxVideoDuration;
    } catch (_) {
      return false;
    } finally {
      await controller.dispose();
    }
  }

  Future<Media?> _uploadPickedFile({required int postId, required XFile file}) async {
    final mediaBytes = await file.readAsBytes();
    return _mediaRepository.uploadMedia(
      postId: postId,
      mediaBytes: mediaBytes,
      fileName: file.name,
    );
  }

  bool _isVideoUrl(String url) {
    final normalizedPath = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
    return normalizedPath.endsWith('.mp4') ||
        normalizedPath.endsWith('.mov') ||
        normalizedPath.endsWith('.webm') ||
        normalizedPath.endsWith('.m4v') ||
        normalizedPath.endsWith('.avi') ||
        normalizedPath.endsWith('.mkv');
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

class _LocalVideoPreview extends StatefulWidget {
  final File videoFile;

  const _LocalVideoPreview({required this.videoFile});

  @override
  State<_LocalVideoPreview> createState() => _LocalVideoPreviewState();
}

class _LocalVideoPreviewState extends State<_LocalVideoPreview> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkVideoPlayer extends StatefulWidget {
  final String url;

  const _NetworkVideoPlayer({required this.url});

  @override
  State<_NetworkVideoPlayer> createState() => _NetworkVideoPlayerState();
}

class _NetworkVideoPlayerState extends State<_NetworkVideoPlayer> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
