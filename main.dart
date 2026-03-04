import 'package:flutter/material.dart';

void main() {
  runApp(const MonApplication());

}

class MonApplication extends StatelessWidget {
  const MonApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mon Projet Dart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, 
      ),
      home: const MaPageAccueil(),
    );
  }
}

class MaPageAccueil extends StatefulWidget {
  const MaPageAccueil({super.key});

  @override
  State<MaPageAccueil> createState() => _MaPageAccueilState();
}

class _MaPageAccueilState extends State<MaPageAccueil> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Premier Projet"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: Main精神.center,
          children: const [
            Icon(Icons.rocket_launch, size: 50, color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(
              "Ton projet commence ici !",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text("Modifie ce texte pour commencer à créer."),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action quand on clique sur le bouton
          print("Bouton cliqué !");
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}