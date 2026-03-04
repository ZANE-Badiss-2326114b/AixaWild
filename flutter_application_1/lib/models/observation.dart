class Observation {
  final String id;
  final String espece;
  final String categorie; // Faune ou Flore
  final DateTime date;
  final double latitude;
  final double longitude;
  final String? photoPath; // Chemin local de l'image

  Observation({
    required this.id,
    required this.espece,
    required this.categorie,
    required this.date,
    required this.latitude,
    required this.longitude,
    this.photoPath,
  });
}