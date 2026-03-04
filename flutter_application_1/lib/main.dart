import 'package:flutter/material.dart';
import 'formulaire.dart'; // Import de la page du formulaire

void main() {
  runApp(const AixaWildApp());
}

class AixaWildApp extends StatelessWidget {
  const AixaWildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AixaWild',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, primary: Colors.green[800]!),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Barre d'application avec un style "Aix-en-Provence"
      appBar: AppBar(
        title: const Text("AixaWild", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.green[800],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. SECTION HEADER / STATS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[800],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const Text("Bienvenue à Aix-en-Provence", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 10),
                  const Text("12 Observations", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  const Text("cette semaine", style: TextStyle(color: Colors.white60)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. BOUTONS D'ACTION RAPIDE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildQuickAction(Icons.map, "Carte", Colors.blue),
                  const SizedBox(width: 15),
                  _buildQuickAction(Icons.list, "Mes fiches", Colors.orange),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. SECTION DERNIÈRES OBSERVATIONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Dernières découvertes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text("Voir tout")),
                ],
              ),
            ),

            // Liste fictive d'observations
            _buildObservationItem("Sanglier", "Faune", "Il y a 2h", Icons.pets),
            _buildObservationItem("Olivier", "Flore", "Hier", Icons.local_florist),
            _buildObservationItem("Cigale", "Faune", "28 Fév", Icons.bug_report),
          ],
        ),
      ),
      
      // LE BOUTON CENTRAL POUR RECENSER (Le coeur du CdC)
      floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    // Navigue vers la page du formulaire
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FormulairePage()),
    );
  },
  label: const Text("Recenser"),
  icon: const Icon(Icons.add_a_photo),
  backgroundColor: Colors.green[700],
  foregroundColor: Colors.white,
),
    );
  }

  // Widget réutilisable pour les petits boutons bleus/oranges
  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Widget pour une ligne d'observation dans la liste
  Widget _buildObservationItem(String titre, String sousTitre, String date, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green[100],
        child: Icon(icon, color: Colors.green[800]),
      ),
      title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(sousTitre),
      trailing: Text(date, style: const TextStyle(color: Colors.grey, fontSize: 12)),
    );
  }
}