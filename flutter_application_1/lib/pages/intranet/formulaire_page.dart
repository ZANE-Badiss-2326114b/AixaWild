import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/api/api_client.dart';
import '../../data/repositories/media_repository.dart';
import '../../data/repositories/post_repository.dart';
import '../../data/utils/species_classifier.dart';
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
  late final MediaRepository _mediaRepository;
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _localisationController = TextEditingController();
  final _imagePicker = ImagePicker();
  List<File> _selectedMediaFiles = [];
  String? _authorEmail;
  bool _isInitialized = false;
  bool _isSubmitting = false;
  bool _isSpeciesValid = false;

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
    _mediaRepository = MediaRepository(ApiClient());
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

    // Vérification que c'est un animal/espèce valide
    if (!SpeciesClassifier.isValidSpecies(nom)) {
      final suggestion = SpeciesClassifier.findClosestMatch(nom);
      final message = suggestion != null
          ? 'Espèce non reconnue. Avez-vous voulu dire "$suggestion" ?'
          : 'Cette espèce n\'est pas reconnue. Veuillez vérifier l\'orthographe ou choisir un animal valide.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
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

      // Upload des fichiers médias s'il y en a
      var uploadedCount = 0;
      var uploadFailed = false;

      for (final mediaFile in _selectedMediaFiles) {
        try {
          final mediaBytes = await mediaFile.readAsBytes();
          final fileName = mediaFile.path.split('/').last;

          await _mediaRepository.uploadMedia(
            postId: created.id,
            mediaBytes: mediaBytes,
            fileName: fileName,
          );

          uploadedCount++;
        } catch (e) {
          uploadFailed = true;
        }
      }

      if (!mounted) {
        return;
      }

      // Message de confirmation
      if (_selectedMediaFiles.isNotEmpty) {
        if (uploadFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$nom enregistré ! $uploadedCount média(s) uploadé(s) avec succès.',
              ),
            ),
          );
        } else if (uploadedCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post créé, mais l\'upload des médias a échoué.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '$nom enregistré ! $uploadedCount média(s) uploadé(s).',
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$nom enregistré avec succès !')),
        );
      }

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

  void _onSpeciesChanged(String value) {
    setState(() {
      _isSpeciesValid =
          value.trim().isEmpty || SpeciesClassifier.isValidSpecies(value);
    });
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (photo != null) {
        setState(() {
          _selectedMediaFiles.add(File(photo.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la capture photo')),
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (image != null) {
        setState(() {
          _selectedMediaFiles.add(File(image.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sélection d\'image')),
      );
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        setState(() {
          _selectedMediaFiles.add(File(video.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sélection de vidéo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Recensement'),
      bottomNavigationBar: intranetBottomNavigationBar(
        context,
        selectedTab: 'Je poste',
      ),
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
        _buildMediaSection(),
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
    final isNotEmpty = _nomController.text.trim().isNotEmpty;
    final hasError = isNotEmpty && !_isSpeciesValid;

    return TextField(
      controller: _nomController,
      textCapitalization: TextCapitalization.words,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: hasError ? Colors.red : Colors.grey,
            width: hasError ? 2 : 1,
          ),
        ),
        labelText: 'Nom de l\'espèce',
        hintText: 'Ex: Sanglier, Olivier, Cigale...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: isNotEmpty
            ? Icon(
                _isSpeciesValid ? Icons.check_circle : Icons.cancel,
                color: _isSpeciesValid ? Colors.green : Colors.red,
              )
            : null,
        errorText: hasError
            ? 'Espèce non reconnue. Veuillez vérifier l\'orthographe.'
            : null,
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

  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4) Ajouter des photos/vidéos (optionnel)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImageFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Appareil photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _pickImageFromGallery,
              icon: const Icon(Icons.image),
              label: const Text('Galerie'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: const Icon(Icons.videocam),
              label: const Text('Vidéo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (_selectedMediaFiles.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${_selectedMediaFiles.length} fichier(s) sélectionné(s)',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedMediaFiles.length,
              itemBuilder: (context, index) {
                final file = _selectedMediaFiles[index];
                final isVideo =
                    file.path.endsWith('.mp4') ||
                    file.path.endsWith('.mov') ||
                    file.path.endsWith('.avi');

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                        ),
                        child: isVideo
                            ? const Center(
                                child: Icon(Icons.videocam, size: 40),
                              )
                            : const Center(child: Icon(Icons.image, size: 40)),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedMediaFiles.removeAt(index);
                            });
                          },
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
