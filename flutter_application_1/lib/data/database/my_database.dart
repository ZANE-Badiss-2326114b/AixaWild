import 'package:drift/drift.dart';
import 'tables/user_table.dart';
import '../daos/user_dao.dart';
import 'connection.dart';
part 'my_database.g.dart';

@DriftDatabase(tables: [Users], daos: [UserDao])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(openDatabaseConnection());
  
  MyDatabase.withExecutor(QueryExecutor e) : super(e); 

  @override
  int get schemaVersion => 1;
}