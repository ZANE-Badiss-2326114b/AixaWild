import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/database/my_database.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../../shared/navigation/app_routes.dart';
import '../../widgets/intranet_appbar.dart';

class AccueilIntranetPage extends StatefulWidget {
  const AccueilIntranetPage({super.key});

  @override
  State<AccueilIntranetPage> createState() => _AccueilIntranetPageState();
}

class _AccueilIntranetPageState extends State<AccueilIntranetPage> {
  final MyDatabase _database = MyDatabase();
  late final PostRepository _postRepository;
  late Future<User?> _userFuture;
  late Future<List<Post>> _postsFuture;
  String _userEmail = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _postRepository = PostRepository(ApiClient());
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument is String && routeArgument.trim().isNotEmpty) {
      _userEmail = routeArgument.trim();
      _userFuture = _database.userDao.getByEmail(_userEmail);
    } else {
      _userFuture = Future.value(null);
    }

    _postsFuture = _postRepository.getAllPosts();

    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild'),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildUserGreetingHeader(),
          const SizedBox(height: 20),
          _buildWelcomeHeader(),
          const SizedBox(height: 20),
          _buildQuickActionsRow(),
          const SizedBox(height: 30),
          _buildDiscoveriesHeader(),
          _buildPostsSection(),
        ],
      ),
    );
  }

  Widget _buildPostsSection() {
    return FutureBuilder<List<Post>>(
      future: _postsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Impossible de charger les posts.'),
          );
        }

        final posts = snapshot.data ?? <Post>[];
        if (posts.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Text('Aucune découverte pour le moment.'),
          );
        }

        return Column(
          children: posts.take(10).map((post) {
            return _buildObservationItem(
              post.title,
              post.content ?? 'Observation',
              _formatRelativeDate(post.createdAt),
              Icons.pets,
            );
          }).toList(),
        );
      },
    );
  }

  String _formatRelativeDate(DateTime? date) {
    if (date == null) return 'Date inconnue';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    }
    if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    }
    if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours} h';
    }
    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildUserGreetingHeader() {
    return FutureBuilder<User?>(
      future: _userFuture,
      builder: (context, snapshot) {
        final user = snapshot.data;

        String displayedName;
        if (user != null) {
          displayedName = user.username;
        } else {
          if (_userEmail.isEmpty) {
            displayedName = 'Utilisateur';
          } else {
            displayedName = _userEmail.split('@').first;
          }
        }

        String typeLabel;
        if (user != null) {
          final localType = user.typeName;
          if (localType != null && localType.trim().isNotEmpty) {
            typeLabel = localType;
          } else {
            typeLabel = 'Free';
          }
        } else {
          typeLabel = 'Free';
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          color: Colors.blue[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour,',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayedName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Abonnement: $typeLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green[800],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: const Column(
        children: [
          Text(
            'Bienvenue à Aix-en-Provence',
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          Text(
            '12 Observations',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'cette semaine',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _buildQuickAction(Icons.map, 'Carte', Colors.blue),
              const SizedBox(width: 15),
              _buildQuickAction(Icons.list, 'Mes fiches', Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.intranetTestPosts,
                  arguments: _userEmail,
                );
              },
              icon: const Icon(Icons.science_outlined),
              label: const Text('Page test Posts & Likes'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveriesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Dernières découvertes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton(onPressed: () {}, child: const Text('Voir tout')),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () {
        Navigator.pushNamed(
          context,
          AppRoutes.intranetFormulaire,
          arguments: _userEmail,
        );
      },
      label: const Text('Recenser'),
      icon: const Icon(Icons.add_a_photo),
      backgroundColor: Colors.green[700],
      foregroundColor: Colors.white,
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildObservationItem(
    String titre,
    String sousTitre,
    String date,
    IconData icon,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green[100],
        child: Icon(icon, color: Colors.green[800]),
      ),
      title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sousTitre),
      trailing: Text(
        date,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}
