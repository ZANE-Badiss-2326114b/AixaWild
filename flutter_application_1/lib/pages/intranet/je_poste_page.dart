import 'package:flutter/material.dart';

import '../../shared/navigation/app_routes.dart';
import '../../widgets/intranet_appbar.dart';

class JePosteIntranetPage extends StatelessWidget {
  const JePosteIntranetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Je poste'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_a_photo, size: 52, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                'Publier un nouveau recensement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.intranetFormulaire);
                },
                icon: const Icon(Icons.edit),
                label: const Text('Ouvrir le formulaire'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}