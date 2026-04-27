import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/repositories/post_repository.dart';
import '../../shared/navigation/app_routes.dart';
import '../../widgets/intranet_bottom_navigation.dart';
import '../../widgets/intranet_appbar.dart';

class FormulaireIntranetPage extends StatefulWidget {
  const FormulaireIntranetPage({super.key});

  @override
  State<FormulaireIntranetPage> createState() => _FormulaireIntranetPageState();
}

class _FormulaireIntranetPageState extends State<FormulaireIntranetPage> {
  late final PostRepository _postRepository;
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _localisationController = TextEditingController();
  String _categorie = 'Faune';
  String? _authorEmail;
  bool _isInitialized = false;
  bool _isSubmitting = false;

  final Dio _geocodingDio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      headers: <String, String>{'User-Agent': 'AixaWild-Flutter-Map/1.0'},
    ),
  );

  @override
  void initState() {
    super.initState();
    _postRepository = PostRepository(ApiClient());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) {
      return;
    }

    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument is String && routeArgument.trim().isNotEmpty) {
      _authorEmail = routeArgument.trim();
    }

    _isInitialized = true;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    _localisationController.dispose();
    super.dispose();
  }

  String _sanitizeInput(String input) {
    final buffer = StringBuffer();
    final allowed = RegExp(r"[a-zA-Z0-9\s\-éèêëàâäùûüôöçœæ'’,.()]");

    for (final char in input.split('')) {
      if (allowed.hasMatch(char)) {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  Future<void> _enregistrerObservation() async {
    final nom = _nomController.text.trim();
    final description = _descriptionController.text.trim();
    final localisation = _localisationController.text.trim();

    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom d\'espèce')),
      );
      return;
    }

    if (localisation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer au moins la ville pour la carte'),
        ),
      );
      return;
    }

    if (!_isValidInput(nom)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caractères non autorisés détectés')),
      );
      return;
    }

    if (_authorEmail == null || _authorEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Email utilisateur manquant. Revenez depuis l\'accueil connecté.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final geocodedPoint = await _geocodeLocation(localisation);
      final contentBuffer = StringBuffer()
        ..writeln('Catégorie: $_categorie')
        ..writeln('Localisation: $localisation');

      if (description.isNotEmpty) {
        contentBuffer.writeln('Description: $description');
      }

      final created = await _postRepository.createPost(
        authorEmail: _authorEmail!,
        title: nom,
        content: contentBuffer.toString().trim(),
        locationName: localisation,
        latitude: geocodedPoint?.latitude,
        longitude: geocodedPoint?.longitude,
      );

      if (!mounted) {
        return;
      }

      if (created == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le post n\'a pas pu être créé.')),
        );
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$nom enregistré avec succès !')));

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.intranetHome,
        (Route<dynamic> route) => false,
        arguments: _authorEmail,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d\'enregistrer le post pour le moment.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _isValidInput(String input) {
    final regex = RegExp(r"^[a-zA-Z0-9\s\-éèêëàâäùûüôöçœæ'’,.()]+$");
    return regex.hasMatch(input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Recensement'),
      bottomNavigationBar: intranetBottomNavigationBar(context, selectedTab: 'Je poste'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        _buildIntroCard(),
        const SizedBox(height: 16),
        _buildTitle(),
        const SizedBox(height: 10),
        _buildSpeciesField(),
        const SizedBox(height: 16),
        _buildDescriptionField(),
        const SizedBox(height: 16),
        _buildLocationField(),
        const SizedBox(height: 16),
        _buildCategorySelector(),
        const SizedBox(height: 24),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildIntroCard() {
    return Card(
      color: Colors.green.withValues(alpha: 0.06),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créer un post détaillé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Ajoutez une espèce, une description et une localisation. La ville est obligatoire pour que le post puisse apparaître sur la carte.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      '1) Espèce observée',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSpeciesField() {
    return TextField(
      controller: _nomController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Nom de l\'espèce',
        hintText: 'Ex: Sanglier, Olivier, Cigale...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: _onSpeciesChanged,
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      minLines: 3,
      maxLines: 5,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Description détaillée',
        hintText: 'Comportement observé, quantité, contexte, heure...',
        prefixIcon: Icon(Icons.notes_outlined),
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildLocationField() {
    return TextField(
      controller: _localisationController,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Localisation',
        hintText: 'Ville obligatoire, adresse complète si possible',
        helperText:
            'La carte utilisera cette information pour positionner le post.',
        prefixIcon: Icon(Icons.place_outlined),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2) Catégorie :', style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: _categorie,
          isExpanded: true,
          items: <String>['Faune', 'Flore'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          onChanged: (nouvelleValeur) {
            setState(() {
              _categorie = nouvelleValeur!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _enregistrerObservation,
        icon: _isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.check),
        label: Text(_isSubmitting ? 'Création...' : 'Créer le post'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F6FB2),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _onSpeciesChanged(String value) {
    final filtered = _sanitizeInput(value);
    if (filtered != value) {
      _nomController.text = filtered;
      _nomController.selection = TextSelection.fromPosition(
        TextPosition(offset: filtered.length),
      );
    }
  }

  Future<_GeocodedPoint?> _geocodeLocation(String location) async {
    try {
      final normalizedAddress = _normalizeAddress(location);

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
        final latitude = double.tryParse((row['lat'] ?? '').toString());
        final longitude = double.tryParse((row['lon'] ?? '').toString());
        if (latitude != null && longitude != null) {
          return _GeocodedPoint(latitude: latitude, longitude: longitude);
        }
      }
    } catch (e) {
      debugPrint('Géocodage échoué pour "$location": $e');
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
}

class _GeocodedPoint {
  const _GeocodedPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
