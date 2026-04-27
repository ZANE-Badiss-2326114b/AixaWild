import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

/// Ouvre la connexion Drift pour plateforme Web.
///
/// Retourne un [QueryExecutor] reposant sur SQLite WASM et persistance
/// IndexedDB via VFS.
QueryExecutor openDatabaseConnection() {
  return DatabaseConnection.delayed(_openWebConnection());
}

/// Initialise l'exécuteur Drift Web.
///
/// Retourne une [DatabaseConnection] prête à l'emploi.
Future<DatabaseConnection> _openWebConnection() async {
  // Charge le moteur SQLite compilé en WASM.
  final sqlite = await WasmSqlite3.loadFromUrl(Uri.parse('sql-wasm.wasm'));

  // Monte un système de fichiers persistant sur IndexedDB.
  final fileSystem = await IndexedDbFileSystem.open(dbName: 'aixawild_databases');

  sqlite.registerVirtualFileSystem(fileSystem, makeDefault: true);

  // Ouvre la base Drift sur le VFS persistant.
  final executor = WasmDatabase(sqlite3: sqlite, path: '/aixawild.sqlite');

  return DatabaseConnection(executor);
}
