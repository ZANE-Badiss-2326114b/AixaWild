import 'package:flutter/material.dart';

import '../../data/api/core/dio_client.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../../widgets/intranet_bottom_navigation.dart';
import '../../widgets/intranet_appbar.dart';

class MesFichesIntranetPage extends StatefulWidget {
  const MesFichesIntranetPage({super.key});

  @override
  State<MesFichesIntranetPage> createState() => _MesFichesIntranetPageState();
}

class _MesFichesIntranetPageState extends State<MesFichesIntranetPage> {
  late final PostRepository _postRepository;
  late Future<List<Post>> _userPostsFuture;
  String _userEmail = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _postRepository = PostRepository(DioApiClient());
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
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: _buildBody(),
      ),
      bottomNavigationBar: intranetBottomNavigationBar(context, selectedTab: 'Mes fiches'),
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
              const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          const Icon(Icons.place_outlined, size: 16, color: Colors.grey),
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
                    Row(
                      children: [
                        Text(
                          _formatDate(post.createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const Spacer(),
                        const Icon(Icons.favorite_border, size: 16, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text('${post.likesCount}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
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

    return userPosts;
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
}