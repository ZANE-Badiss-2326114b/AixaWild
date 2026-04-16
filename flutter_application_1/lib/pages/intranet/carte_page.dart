import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../data/api/core/dio_client.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../../widgets/intranet_appbar.dart';

class CarteIntranetPage extends StatefulWidget {
  const CarteIntranetPage({super.key});

  @override
  State<CarteIntranetPage> createState() => _CarteIntranetPageState();
}

class _CarteIntranetPageState extends State<CarteIntranetPage> {
  late final PostRepository _postRepository;
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postRepository = PostRepository(DioApiClient());
    _postsFuture = _postRepository.getAllPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Carte'),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<Post>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return ListView(
                children: [
                  SizedBox(height: 180),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  _EmptyState(
                    icon: Icons.error_outline,
                    title: 'Impossible de charger la carte',
                    subtitle: 'Vérifie la connexion API puis réessaie.',
                  ),
                ],
              );
            }

            final posts = snapshot.data ?? <Post>[];
            final postsWithLocation = posts.where((post) => post.hasLocation).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(totalPosts: posts.length, locatedPosts: postsWithLocation.length),
                const SizedBox(height: 16),
                if (postsWithLocation.isEmpty)
                  const _EmptyState(
                    icon: Icons.map_outlined,
                    title: 'Aucun emplacement trouvé',
                    subtitle: 'Les posts doivent contenir latitude/longitude ou un champ adresse exploitable.',
                  )
                else ...[
                  SizedBox(height: 380, child: _PostsMap(posts: postsWithLocation)),
                  const SizedBox(height: 16),
                  const Text('Emplacements liés aux posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...postsWithLocation.map((post) => _PostLocationCard(post: post)),
                ],
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshPosts,
        icon: const Icon(Icons.refresh),
        label: const Text('Actualiser'),
      ),
    );
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _postsFuture = _postRepository.getAllPosts();
    });
    await _postsFuture;
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.totalPosts, required this.locatedPosts});

  final int totalPosts;
  final int locatedPosts;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carte des observations',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$locatedPosts emplacement(s) affiché(s) sur $totalPosts post(s)',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _PostsMap extends StatefulWidget {
  const _PostsMap({required this.posts});

  final List<Post> posts;

  @override
  State<_PostsMap> createState() => _PostsMapState();
}

class _PostsMapState extends State<_PostsMap> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final markers = widget.posts
        .where((post) => post.hasLocation)
        .map(
          (post) => Marker(
            point: LatLng(post.latitude!, post.longitude!),
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => _showPostBottomSheet(context, post),
              child: const Icon(Icons.location_on, size: 44, color: Colors.redAccent),
            ),
          ),
        )
        .toList();

    final initialCenter = _computeCenter(widget.posts) ?? const LatLng(43.5297, 5.4474);
    final bounds = _computeBounds(widget.posts);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: initialCenter,
          initialZoom: bounds == null ? 11 : 10,
          minZoom: 4,
          maxZoom: 18,
          onMapReady: () {
            if (bounds != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _mapController.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(48),
                    ),
                  );
                }
              });
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'flutter_application_1',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }

  LatLng? _computeCenter(List<Post> posts) {
    final locatedPosts = posts.where((post) => post.hasLocation).toList();
    if (locatedPosts.isEmpty) return null;

    final latSum = locatedPosts.fold<double>(0, (sum, post) => sum + post.latitude!);
    final lonSum = locatedPosts.fold<double>(0, (sum, post) => sum + post.longitude!);
    return LatLng(latSum / locatedPosts.length, lonSum / locatedPosts.length);
  }

  LatLngBounds? _computeBounds(List<Post> posts) {
    final locatedPosts = posts.where((post) => post.hasLocation).toList();
    if (locatedPosts.isEmpty) return null;

    return LatLngBounds.fromPoints(locatedPosts.map((post) => LatLng(post.latitude!, post.longitude!)).toList());
  }

  void _showPostBottomSheet(BuildContext context, Post post) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(post.locationName ?? 'Emplacement sans nom'),
                const SizedBox(height: 6),
                Text('Lat: ${post.latitude?.toStringAsFixed(5)}  Lon: ${post.longitude?.toStringAsFixed(5)}'),
                const SizedBox(height: 6),
                Text(post.content ?? 'Observation'),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PostLocationCard extends StatelessWidget {
  const _PostLocationCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.place, color: Colors.green),
        title: Text(post.title),
        subtitle: Text(
          [
            if (post.locationName != null && post.locationName!.trim().isNotEmpty) post.locationName!,
            if (post.latitude != null && post.longitude != null) '${post.latitude!.toStringAsFixed(4)}, ${post.longitude!.toStringAsFixed(4)}',
          ].join('\n'),
        ),
        isThreeLine: true,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(post.locationName ?? 'Emplacement sans nom'),
                    const SizedBox(height: 6),
                    Text('Lat: ${post.latitude?.toStringAsFixed(5)}  Lon: ${post.longitude?.toStringAsFixed(5)}'),
                    const SizedBox(height: 6),
                    Text(post.content ?? 'Observation'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}