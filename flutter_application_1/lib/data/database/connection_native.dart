import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Ouvre la connexion Drift pour plateformes IO.
///
/// Retourne un [QueryExecutor] en `LazyDatabase` afin de différer l'ouverture
/// du fichier SQLite jusqu'au premier accès effectif.
QueryExecutor openDatabaseConnection() {
  return LazyDatabase(() async {
    // Résolution du chemin applicatif standard puis création/ouverte du fichier DB.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'aixawild.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
