import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:sqlite3/wasm.dart';

QueryExecutor openDatabaseConnection() {
  return DatabaseConnection.delayed(_openWebConnection());
}

Future<DatabaseConnection> _openWebConnection() async {
  final sqlite = await WasmSqlite3.loadFromUrl(
    Uri.parse('sql-wasm.wasm'),
  );

  final fileSystem = await IndexedDbFileSystem.open(
    dbName: 'aixawild_databases',
  );

  sqlite.registerVirtualFileSystem(
    fileSystem,
    makeDefault: true,
  );

  final executor = WasmDatabase(
    sqlite3: sqlite,
    path: '/aixawild.sqlite',
  );

  return DatabaseConnection(executor);
}