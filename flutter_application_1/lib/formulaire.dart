import 'package:flutter/material.dart';
import 'main.dart'; // Très important pour revenir au main

class FormulairePage extends StatefulWidget {
  const FormulairePage({super.key});

  @override
  State<FormulairePage> createState() => _FormulairePageState();
}

class _FormulairePageState extends State<FormulairePage> {
  final _nomController = TextEditingController();
  String _categorie = 'Faune';

  void _enregistrerObservation() {
    if (_nomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom d\'espèce')),
      );
      return;
    }
    
    final dateActuelle = DateTime.now(); 
    print("Enregistré le : ${dateActuelle.day}/${dateActuelle.month} à ${dateActuelle.hour}:${dateActuelle.minute}, Observation : ${_nomController.text} ($_categorie)");
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nomController.text} enregistré avec succès !')),
    );
    
    // Retour immédiat à l'accueil avec la SnackBar qui reste visible
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
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
            
            const Spacer(),
            
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