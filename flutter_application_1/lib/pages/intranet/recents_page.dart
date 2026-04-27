import 'package:flutter/material.dart';

import '../../data/api/core/dio_client.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../../widgets/intranet_appbar.dart';
import '../../widgets/intranet_bottom_navigation.dart';

class RecentsIntranetPage extends StatefulWidget {
  const RecentsIntranetPage({super.key});

  @override
  State<RecentsIntranetPage> createState() => _RecentsIntranetPageState();
}

class _RecentsIntranetPageState extends State<RecentsIntranetPage> {
  late final PostRepository _postRepository;
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postRepository = PostRepository(DioApiClient());
    _postsFuture = _loadRecents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Récents'),
      bottomNavigationBar: intranetBottomNavigationBar(context, selectedTab: 'Récents'),
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
                    'Impossible de charger les posts récents.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _postsFuture = _loadRecents();
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
                    'Aucun post disponible pour le moment.',
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
                            Text('#${post.id}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if ((post.content ?? '').trim().isNotEmpty) Text(post.content!.trim()),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(_formatDate(post.createdAt), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const Spacer(),
                            Text(post.authorEmail, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Post>> _loadRecents() async {
    final posts = await _postRepository.getAllPosts();
    posts.sort(_sortNewestFirst);
    return posts;
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _loadRecents();
    });
    await _postsFuture;
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
}
