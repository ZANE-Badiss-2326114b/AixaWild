import 'package:flutter/material.dart';

import '../../shared/navigation/app_routes.dart';

class ExplicationIntranetPage extends StatelessWidget {
  const ExplicationIntranetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildTopBar(),
      body: const _ExplicationBody(),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  PreferredSizeWidget _buildTopBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      title: const Text('AixaWild', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
      actions: const [
        Icon(Icons.search, size: 30),
        SizedBox(width: 10),
        Icon(Icons.supervised_user_circle, size: 30),
        SizedBox(width: 10),
        _BadgeIcon(icon: Icons.chat, badge: '2'),
        SizedBox(width: 10),
        _BadgeIcon(icon: Icons.settings, badge: '2'),
        SizedBox(width: 10),
      ],
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab(context, 'Récentes', AppRoutes.intranetMesFiches),
            _buildTab(context, 'Espèces', AppRoutes.intranetMesFiches),
            _buildTab(context, 'Messages', AppRoutes.intranetMessages),
            _buildTab(context, 'Je poste', AppRoutes.intranetJePoste),
            _buildTab(context, 'Carte', AppRoutes.intranetCarte),
            _buildTab(context, 'Explication', AppRoutes.intranetExplication, selected: true),
            _buildTab(context, 'Contributeur', null),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(
    BuildContext context,
    String label,
    String? targetRoute, {
    bool selected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        selected: selected,
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onSelected: (_) {
          if (targetRoute == null || selected) {
            return;
          }
          Navigator.pushReplacementNamed(context, targetRoute);
        },
        selectedColor: Colors.blue[700],
        backgroundColor: Colors.blue[100],
        labelStyle: TextStyle(
          color: selected ? Colors.white : Colors.blue[900],
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ExplicationBody extends StatelessWidget {
  const _ExplicationBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 10),
            Text(
              'AixaWild est une application pensée pour les passionnés de nature, d\'observation animale et de suivi de la faune sauvage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, height: 1.45),
            ),
            SizedBox(height: 22),
            Text(
              'Elle permet de centraliser et partager des photos et vidéos issues de pièges photographiques, caméras automatiques ou tout autre dispositif d\'observation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, height: 1.45),
            ),
            SizedBox(height: 22),
            Text(
              'Ici, pas de course aux likes, juste le plaisir de partager un instant furtif capturé dans le calme d\'un sous-bois ou sur un sentier de montagne.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, height: 1.45),
            ),
            SizedBox(height: 22),
            Text(
              'Regardez, uploadez, classez, partagez, analysez et consultez facilement les observations, enrichies de données contextuelles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, height: 1.45, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 22),
            Text(
              'Conçue pour les naturalistes amateurs, les randonneurs curieux et les gestionnaires d\'espaces naturels, AixaWild propose une interface simple et intuitive pour partager vos rencontres avec le vivant.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, height: 1.45),
            ),
            SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.icon, required this.badge});

  final IconData icon;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: 30),
        Positioned(
          right: -6,
          top: -5,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              badge,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}