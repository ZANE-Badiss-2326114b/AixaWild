import 'package:flutter/material.dart';

void main() {
  runApp(const AixaWildApp());
}

class AixaWildApp extends StatelessWidget {
  const AixaWildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AixaWild',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const AddObservationScreen(),
    );
  }
}

class AddObservationScreen extends StatefulWidget {
  const AddObservationScreen({super.key});

  @override
  State<AddObservationScreen> createState() => _AddObservationScreenState();
}

class _AddObservationScreenState extends State<AddObservationScreen> {
  // Les "contrôleurs" permettent de récupérer ce que l'utilisateur écrit
  final _nomController = TextEditingController();
  String _categorie = 'Faune'; // Valeur par défaut

  void _enregistrerObservation() {
    if (_nomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom d\'espèce')),
      );
      return;
    }
    
    // Pour l'instant on affiche juste dans la console
    print("Observation : ${_nomController.text} ($_categorie)");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nomController.text} enregistré avec succès !')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AixaWild - Recensement"),
        backgroundColor: Colors.green.shade100,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quelle espèce avez-vous vue ?", 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            
            // Champ de texte pour le nom
            TextField(
              controller: _nomController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Ex: Sanglier, Olivier, Cigale...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            
            const SizedBox(height: 25),
            
            const Text("Catégorie :", style: TextStyle(fontSize: 16)),
            // Menu déroulant pour la catégorie
            DropdownButton<String>(
              value: _categorie,
              isExpanded: true,
              items: <String>['Faune', 'Flore'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (nouvelleValeur) {
                setState(() {
                  _categorie = nouvelleValeur!;
                });
              },
            ),
            
            const SizedBox(height: 25), // Pousse le bouton vers le bas
            
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _enregistrerObservation,
                icon: const Icon(Icons.check),
                label: const Text("Enregistrer l'observation"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}