import 'package:drift/drift.dart';
import 'package:flutter_application_1/data/daos/user_dao.dart';
import 'package:flutter_application_1/data/database/connection.dart';
import 'package:flutter_application_1/data/database/tables/user_table.dart';
part 'my_database.g.dart';

/// Point d'entrée Drift de la couche Data locale.
///
/// Cette base centralise les tables et DAO utilisés par les repositories pour
/// les scénarios offline/cache.
@DriftDatabase(tables: [Users], daos: [UserDao])
class MyDatabase extends _$MyDatabase {
  /// Construit la base avec l'exécuteur adapté à la plateforme courante.
  ///
  /// Retourne une base connectée via `openDatabaseConnection()`.
  MyDatabase() : super(openDatabaseConnection());

  /// Construit la base avec un exécuteur injecté (tests/intégration).
  ///
  /// [e] est un [QueryExecutor] Drift fourni par l'appelant.
  MyDatabase.withExecutor(super.e);

  @override
  /// Version du schéma Drift.
  ///
  /// Retourne l'entier de version courant.
  int get schemaVersion => 1;
}
