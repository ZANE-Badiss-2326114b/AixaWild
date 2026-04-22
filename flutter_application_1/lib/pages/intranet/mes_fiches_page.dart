import 'package:flutter/material.dart';

import '../../shared/navigation/app_routes.dart';
import '../../widgets/intranet_appbar.dart';

class MesFichesIntranetPage extends StatefulWidget {
  const MesFichesIntranetPage({super.key});

  @override
  State<MesFichesIntranetPage> createState() => _MesFichesIntranetPageState();
}

class _MesFichesIntranetPageState extends State<MesFichesIntranetPage> {
  static const _navItems = [
    'Récentes',
    'Espèces',
    'Messages',
    'Je poste',
    'Carte',
    'Explication',
    'Contributeur',
  ];

  final List<_Species> _speciesRanking = const [
    _Species('Renard', 326, 'https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=800'),
    _Species('Chevreuil', 284, 'https://images.unsplash.com/photo-1549366021-9f761d040a94?w=800'),
    _Species('Lièvre', 249, 'https://images.unsplash.com/photo-1585110396000-c9ffd4e4b308?w=800'),
    _Species('Loup', 221, 'https://images.unsplash.com/photo-1474511016488-2f4dbbc6aeb9?w=800'),
    _Species('Mouflon', 198, 'https://images.unsplash.com/photo-1526498460520-4c246339dccb?w=800'),
    _Species('Sanglier', 177, 'https://images.unsplash.com/photo-1611758497398-4f7f89f4ae0c?w=800'),
  ];

  late _Species _selectedSpecies;
  String _selectedNav = 'Espèces';

  @override
  void initState() {
    super.initState();
    _selectedSpecies = _speciesRanking.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Mes fiches'),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildBody() {
    if (_selectedNav == 'Espèces') {
      return _buildSpeciesRanking();
    }

    if (_selectedNav == 'Récentes') {
      return _buildRecentSightings();
    }

    return Center(
      child: Text(
        'Section $_selectedNav',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSpeciesRanking() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 150,
          ),
          itemCount: _speciesRanking.length,
          itemBuilder: (context, index) {
            final species = _speciesRanking[index];
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedSpecies = species;
                  _selectedNav = 'Récentes';
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      species.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: Colors.blue[100],
                        child: const Icon(Icons.pets, size: 36),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        color: Colors.black54,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                species.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '#${index + 1}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecentSightings() {
    final recensements = _buildSampleSightings(_selectedSpecies.name);

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          decoration: BoxDecoration(
            color: Colors.blue[800],
            borderRadius: BorderRadius.circular(8),
          ),
          child: SizedBox(
            height: 112,
            child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedSpecies.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '+ d\'infos wikipedia',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: SizedBox(
                  width: 96,
                  height: 112,
                  child: Image.network(_selectedSpecies.imageUrl, fit: BoxFit.cover),
                ),
              ),
            ],
          ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recensements.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = recensements[index];
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade100),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      height: 64,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        child: Image.network(item.imageUrl, fit: BoxFit.cover),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.place,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            const Text('FR - département', style: TextStyle(fontSize: 11)),
                            Text(item.date, style: const TextStyle(fontSize: 11)),
                            const Text('Pseudo user', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '❤${_selectedSpecies.score}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _navItems.map((item) {
            final isSelected = _selectedNav == item;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                selected: isSelected,
                label: Text(item, style: const TextStyle(fontSize: 12)),
                onSelected: (_) {
                  final routeName = _routeForTab(item);
                  if (routeName != null) {
                    Navigator.pushNamed(context, routeName);
                    return;
                  }

                  setState(() {
                    _selectedNav = item;
                  });
                },
                selectedColor: Colors.blue[700],
                backgroundColor: Colors.blue[100],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.blue[900],
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<_Recensement> _buildSampleSightings(String speciesName) {
    return [
      _Recensement('Massif du Dévoluy', '03 Juin 2025', _selectedSpecies.imageUrl),
      _Recensement('Massif du Dévoluy', '02 Avril 2025', 'https://images.unsplash.com/photo-1519904981063-b0cf448d479e?w=800'),
      _Recensement('Regagnas', '19 Mars 2025', 'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800'),
      _Recensement('Regagnas', '16 Mars 2025', 'https://images.unsplash.com/photo-1473448912268-2022ce9509d8?w=800'),
      _Recensement('Aix-en-Provence', '10 Mars 2025', 'https://images.unsplash.com/photo-1448375240586-882707db888b?w=800'),
    ].map((item) => item.copyWith(species: speciesName)).toList();
  }

  String? _routeForTab(String tab) {
    switch (tab) {
      case 'Messages':
        return AppRoutes.intranetMessages;
      case 'Je poste':
        return AppRoutes.intranetJePoste;
      case 'Carte':
        return AppRoutes.intranetCarte;
      case 'Explication':
        return AppRoutes.intranetExplication;
      default:
        return null;
    }
  }
}

class _Species {
  const _Species(this.name, this.score, this.imageUrl);

  final String name;
  final int score;
  final String imageUrl;
}

class _Recensement {
  const _Recensement(this.place, this.date, this.imageUrl, {this.species = ''});

  final String place;
  final String date;
  final String imageUrl;
  final String species;

  _Recensement copyWith({String? species}) {
    return _Recensement(place, date, imageUrl, species: species ?? this.species);
  }
}