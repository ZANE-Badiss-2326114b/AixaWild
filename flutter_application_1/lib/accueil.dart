import 'package:flutter/material.dart';

// Si tu as défini ta classe Observation dans observation.dart, 
// tu pourras l'importer ici plus tard. Pour l'instant, on utilise une liste simple.

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // 1. Nos fausses données d'observation pour tester le design
  final List<Map<String, String>> recentActivities = const [
    {
      'species': 'Renard roux',
      'user': 'AliceNature',
      'location': 'Forêt de Fontainebleau',
      'time': 'Il y a 2 heures',
      'image': 'https://images.unsplash.com/photo-1516934024742-b461fba47600?w=500', // Image temporaire
    },
    {
      'species': 'Chouette hulotte',
      'user': 'Bob_Observateur',
      'location': 'Parc des Calanques',
      'time': 'Il y a 5 heures',
      'image': 'https://images.unsplash.com/photo-1549685368-24ce5deaf27b?w=500',
    },
    {
      'species': 'Cerf élaphe',
      'user': 'CamilleWild',
      'location': 'Massif des Vosges',
      'time': 'Hier',
      'image': 'https://images.unsplash.com/photo-1484406593171-20164b7325dd?w=500',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Activité récente', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // 2. Création de la liste déroulante
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: recentActivities.length,
        itemBuilder: (context, index) {
          final activity = recentActivities[index];
          
          // 3. Le design de chaque "Carte" d'observation
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
            elevation: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête de la carte : Photo de profil (icône) et Nom d'utilisateur
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(activity['user']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${activity['location']} • ${activity['time']}'),
                  trailing: const Icon(Icons.more_vert),
                ),
                
                // La photo de l'observation
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    activity['image']!,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                
                // Pied de la carte : Nom de l'espèce et boutons d'interaction
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['species']!,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          IconButton(icon: const Icon(Icons.favorite_border), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.comment_outlined), onPressed: () {}),
                          const Spacer(),
                          IconButton(icon: const Icon(Icons.share_outlined), onPressed: () {}),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}