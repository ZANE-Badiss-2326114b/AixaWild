import 'package:drift/drift.dart';

/// Implémentation de secours pour plateforme non supportée.
///
/// Retourne une erreur explicite à l'initialisation de la base locale.
QueryExecutor openDatabaseConnection() {
  throw UnsupportedError('Plateforme non supportée pour la base de données.');
}
