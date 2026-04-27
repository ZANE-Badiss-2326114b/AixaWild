import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/data/api/core/dio_client.dart';
import 'package:flutter_application_1/data/models/post.dart';
import 'package:flutter_application_1/data/repositories/opinion_repository.dart';
import 'package:flutter_application_1/data/repositories/post_repository.dart';
import 'package:flutter_application_1/pages/admin/admin_guard.dart';
import 'package:flutter_application_1/pages/admin/providers/admin_post_monitoring_provider.dart';
import 'package:flutter_application_1/widgets/intranet_appbar.dart';

class PostMonitoringPage extends StatefulWidget {
  const PostMonitoringPage({super.key});

  @override
  State<PostMonitoringPage> createState() => _PostMonitoringPageState();
}

class _PostMonitoringPageState extends State<PostMonitoringPage> {
  late final AdminPostMonitoringProvider _provider;

  @override
  void initState() {
    super.initState();

    final apiClient = DioApiClient(
      onForbidden: (message) async {
        _showMessage(message);
      },
    );

    _provider = AdminPostMonitoringProvider(
      postRepository: PostRepository(apiClient),
      opinionRepository: OpinionRepository(apiClient),
    );

    _provider.loadPosts();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeArgument = ModalRoute.of(context)?.settings.arguments;

    return AdminGuard(
      redirectArguments: routeArgument,
      child: ChangeNotifierProvider<AdminPostMonitoringProvider>.value(
        value: _provider,
        child: Scaffold(
          appBar: intranetAppBar(title: 'Monitoring des publications'),
          body: Consumer<AdminPostMonitoringProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final posts = provider.posts;
              if (posts.isEmpty) {
                return const Center(child: Text('Aucune publication trouvée.'));
              }

              return RefreshIndicator(
                onRefresh: provider.loadPosts,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: posts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final stats = provider.statsByPost[post.id] ??
                        PostEngagementStats(
                          likes: post.likesCount,
                          reports: post.reportingCount,
                        );

                    return _buildPostCard(provider, post, stats);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(
    AdminPostMonitoringProvider provider,
    Post post,
    PostEngagementStats stats,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Auteur: ${post.authorEmail}'),
            const SizedBox(height: 10),
            Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                  label: Text('Likes: ${stats.likes}'),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.report_gmailerrorred, size: 18),
                  label: Text('Signalements: ${stats.reports}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: Icon(Icons.delete_forever, color: Colors.red.shade700),
                tooltip: 'Supprimer publication',
                onPressed: () => _confirmDeletePost(provider, post.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeletePost(AdminPostMonitoringProvider provider, int postId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Suppression publication'),
          content: Text('Supprimer la publication #$postId ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      final success = await provider.deletePost(postId);
      if (!mounted) {
        return;
      }

      if (success) {
        _showMessage('Publication supprimée.');
      } else {
        _showMessage(provider.errorMessage ?? 'Suppression impossible.');
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
