import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';

import '../../data/api/core/dio_client.dart';
import '../../data/models/post.dart';
import '../../data/repositories/post_repository.dart';
import '../../widgets/intranet_bottom_navigation.dart';
import '../../widgets/intranet_appbar.dart';

class CarteIntranetPage extends StatefulWidget {
  const CarteIntranetPage({super.key});

  @override
  State<CarteIntranetPage> createState() => _CarteIntranetPageState();
}

class _CarteIntranetPageState extends State<CarteIntranetPage> {
  late final PostRepository _postRepository;
  late Future<List<_MappedPost>> _postsFuture;
  final Dio _geocodingDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: const <String, dynamic>{
        'User-Agent': 'AixaWild-Flutter-Map/1.0',
      },
    ),
  );

  bool _isSeedingPosts = false;
  String _authorEmail = '';
  bool _routeInitialized = false;

  @override
  void initState() {
    super.initState();
    _postRepository = PostRepository(DioApiClient());
    _postsFuture = _loadMappedPosts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_routeInitialized) return;

    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument is String) {
      _authorEmail = routeArgument.trim();
    }

    _routeInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Carte'),
      bottomNavigationBar: intranetBottomNavigationBar(context, selectedTab: 'Carte'),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: FutureBuilder<List<_MappedPost>>(
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

            final mappedPosts = snapshot.data ?? <_MappedPost>[];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(
                  totalPosts: mappedPosts.length,
                  locatedPosts: mappedPosts.length,
                ),
                const SizedBox(height: 16),
                _SeedPostsCard(
                  isLoading: _isSeedingPosts,
                  onCreate: _seedPostsWithAddresses,
                  hasAuthorEmail: _authorEmail.isNotEmpty,
                ),
                const SizedBox(height: 16),
                if (mappedPosts.isEmpty)
                  const _EmptyState(
                    icon: Icons.map_outlined,
                    title: 'Aucun emplacement trouvé',
                    subtitle:
                        'Les posts doivent contenir latitude/longitude ou un champ adresse exploitable.',
                  )
                else ...[
                  SizedBox(height: 380, child: _PostsMap(posts: mappedPosts)),
                  const SizedBox(height: 16),
                  const Text(
                    'Emplacements liés aux posts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...mappedPosts.map((post) => _PostLocationCard(post: post)),
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
      _postsFuture = _loadMappedPosts();
    });
    await _postsFuture;
  }

  Future<List<_MappedPost>> _loadMappedPosts() async {
    final posts = await _postRepository.getAllPosts();
    final mapped = <_MappedPost>[];

    for (final post in posts) {
      final directLat = post.latitude;
      final directLon = post.longitude;
      if (directLat != null && directLon != null) {
        mapped.add(
          _MappedPost(
            post: post,
            latitude: directLat,
            longitude: directLon,
            resolvedAddress: post.locationName,
          ),
        );
        continue;
      }

      final rawAddress = _extractAddress(post);
      if (rawAddress == null) {
        continue;
      }

      final geo = await _geocodeAddress(rawAddress);
      if (geo != null) {
        mapped.add(
          _MappedPost(
            post: post,
            latitude: geo.latitude,
            longitude: geo.longitude,
            resolvedAddress: rawAddress,
          ),
        );
      } else {
        final fallback = _getFallbackCoordinates(rawAddress);
        if (fallback != null) {
          mapped.add(
            _MappedPost(
              post: post,
              latitude: fallback.latitude,
              longitude: fallback.longitude,
              resolvedAddress: rawAddress,
            ),
          );
        }
      }
    }

    return mapped;
  }

  String? _extractAddress(Post post) {
    if (post.locationName != null && post.locationName!.trim().isNotEmpty) {
      return post.locationName!.trim();
    }

    final content = post.content?.trim();
    if (content == null || content.isEmpty) {
      return null;
    }

    for (final pattern in [
      r'Localisation\s*:\s*(.+)',
      r'Adresse\s*:\s*(.+)',
      r'Lieu\s*:\s*(.+)',
    ]) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(content);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty) {
          return extracted;
        }
      }
    }

    return null;
  }

  Future<_GeocodedPoint?> _geocodeAddress(String address) async {
    try {
      final normalizedAddress = _normalizeAddress(address);

      final fallbackCoords = _getFallbackCoordinates(normalizedAddress);
      if (fallbackCoords != null) {
        return fallbackCoords;
      }

      final response = await _geocodingDio.get<dynamic>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: <String, dynamic>{
          'q': normalizedAddress,
          'format': 'jsonv2',
          'limit': 1,
          'countrycodes': 'fr',
        },
      );

      final data = response.data;
      if (data is List &&
          data.isNotEmpty &&
          data.first is Map<String, dynamic>) {
        final row = data.first as Map<String, dynamic>;
        final lat = double.tryParse((row['lat'] ?? '').toString());
        final lon = double.tryParse((row['lon'] ?? '').toString());
        if (lat != null && lon != null) {
          return _GeocodedPoint(latitude: lat, longitude: lon);
        }
      }
    } catch (e) {
      debugPrint('Géocodage échoué pour "$address": $e');
    }

    return null;
  }

  String _normalizeAddress(String address) {
    return address.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  _GeocodedPoint? _getFallbackCoordinates(String address) {
    final lowerAddress = address.toLowerCase();
    final fallbacks = <String, _GeocodedPoint>{
      'salon': _GeocodedPoint(latitude: 43.6452, longitude: 5.0936),
      'salon de provence': _GeocodedPoint(latitude: 43.6452, longitude: 5.0936),
      'salon-de-provence': _GeocodedPoint(latitude: 43.6452, longitude: 5.0936),
      'aix': _GeocodedPoint(latitude: 43.5298, longitude: 5.4474),
      'aix-en-provence': _GeocodedPoint(latitude: 43.5298, longitude: 5.4474),
      'marseille': _GeocodedPoint(latitude: 43.2965, longitude: 5.3698),
      'avignon': _GeocodedPoint(latitude: 43.9516, longitude: 4.8057),
      'cannes': _GeocodedPoint(latitude: 43.5525, longitude: 7.0176),
      'nice': _GeocodedPoint(latitude: 43.7102, longitude: 7.2625),
    };

    for (final key in fallbacks.keys) {
      if (lowerAddress.contains(key)) {
        return fallbacks[key];
      }
    }

    return null;
  }

  Future<void> _seedPostsWithAddresses() async {
    if (_authorEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email utilisateur manquant pour créer les posts. Reviens depuis l\'accueil connecté.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSeedingPosts = true;
    });

    final templates = <_SeedAddressPost>[
      _SeedAddressPost(
        title: 'Observation au Parc Jourdan',
        address: 'Parc Jourdan, Aix-en-Provence',
      ),
      _SeedAddressPost(
        title: 'Observation sur le Cours Mirabeau',
        address: 'Cours Mirabeau, Aix-en-Provence',
      ),
      _SeedAddressPost(
        title: 'Observation proche de la Rotonde',
        address: 'Fontaine de la Rotonde, Aix-en-Provence',
      ),
      _SeedAddressPost(
        title: 'Observation à la Sainte-Victoire',
        address: 'Le Tholonet, Aix-en-Provence',
      ),
    ];

    var createdCount = 0;
    try {
      for (final item in templates) {
        final geo = await _geocodeAddress(item.address);
        if (geo == null) {
          continue;
        }

        final created = await _postRepository.createPost(
          authorEmail: _authorEmail,
          title: item.title,
          content: 'Post de démonstration carte.\nAdresse: ${item.address}',
          locationName: item.address,
          latitude: geo.latitude,
          longitude: geo.longitude,
        );

        if (created != null) {
          createdCount++;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSeedingPosts = false;
          _postsFuture = _loadMappedPosts();
        });
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$createdCount post(s) créés avec adresse et coordonnées.',
        ),
      ),
    );
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
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
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

  final List<_MappedPost> posts;

  @override
  State<_PostsMap> createState() => _PostsMapState();
}

class _PostsMapState extends State<_PostsMap> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final markers = widget.posts
        .map(
          (post) => Marker(
            point: LatLng(post.latitude, post.longitude),
            width: 48,
            height: 48,
            child: GestureDetector(
              onTap: () => _showPostBottomSheet(context, post),
              child: const Icon(
                Icons.location_on,
                size: 44,
                color: Colors.redAccent,
              ),
            ),
          ),
        )
        .toList();

    final initialCenter =
        _computeCenter(widget.posts) ?? const LatLng(43.5297, 5.4474);
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

  LatLng? _computeCenter(List<_MappedPost> posts) {
    if (posts.isEmpty) return null;

    final latSum = posts.fold<double>(0, (sum, post) => sum + post.latitude);
    final lonSum = posts.fold<double>(0, (sum, post) => sum + post.longitude);
    return LatLng(latSum / posts.length, lonSum / posts.length);
  }

  LatLngBounds? _computeBounds(List<_MappedPost> posts) {
    if (posts.isEmpty) return null;

    return LatLngBounds.fromPoints(
      posts.map((post) => LatLng(post.latitude, post.longitude)).toList(),
    );
  }

  void _showPostBottomSheet(BuildContext context, _MappedPost post) {
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
                Text(
                  post.post.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.resolvedAddress ??
                      post.post.locationName ??
                      'Emplacement sans nom',
                ),
                const SizedBox(height: 6),
                Text(
                  'Lat: ${post.latitude.toStringAsFixed(5)}  Lon: ${post.longitude.toStringAsFixed(5)}',
                ),
                const SizedBox(height: 6),
                Text(post.post.content ?? 'Observation'),
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

  final _MappedPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.place, color: Colors.green),
        title: Text(post.post.title),
        subtitle: Text(
          [
            if (post.resolvedAddress != null &&
                post.resolvedAddress!.trim().isNotEmpty)
              post.resolvedAddress!,
            '${post.latitude.toStringAsFixed(4)}, ${post.longitude.toStringAsFixed(4)}',
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
                    Text(
                      post.post.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.resolvedAddress ??
                          post.post.locationName ??
                          'Emplacement sans nom',
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Lat: ${post.latitude.toStringAsFixed(5)}  Lon: ${post.longitude.toStringAsFixed(5)}',
                    ),
                    const SizedBox(height: 6),
                    Text(post.post.content ?? 'Observation'),
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
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _SeedPostsCard extends StatelessWidget {
  const _SeedPostsCard({
    required this.isLoading,
    required this.onCreate,
    required this.hasAuthorEmail,
  });

  final bool isLoading;
  final Future<void> Function() onCreate;
  final bool hasAuthorEmail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Créer des posts de démo',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              hasAuthorEmail
                  ? 'Crée automatiquement des posts avec plusieurs adresses d\'Aix-en-Provence.'
                  : 'Email utilisateur absent: retourne à l\'accueil connecté puis rouvre la carte.',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading || !hasAuthorEmail ? null : onCreate,
                icon: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_location_alt),
                label: Text(
                  isLoading
                      ? 'Création en cours...'
                      : 'Créer 4 posts avec adresses',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MappedPost {
  const _MappedPost({
    required this.post,
    required this.latitude,
    required this.longitude,
    this.resolvedAddress,
  });

  final Post post;
  final double latitude;
  final double longitude;
  final String? resolvedAddress;
}

class _GeocodedPoint {
  const _GeocodedPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class _SeedAddressPost {
  const _SeedAddressPost({required this.title, required this.address});

  final String title;
  final String address;
}
