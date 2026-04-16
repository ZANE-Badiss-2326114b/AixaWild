import 'package:drift/drift.dart';
import 'package:flutter_application_1/data/daos/user_dao.dart';
import 'package:flutter_application_1/data/database/connection.dart';
import 'package:flutter_application_1/data/database/tables/user_table.dart';
part 'my_database.g.dart';

@DriftDatabase(tables: [Users], daos: [UserDao])
class MyDatabase extends _$MyDatabase {
  MyDatabase() : super(openDatabaseConnection());
  
  MyDatabase.withExecutor(super.e); 

  @override
  int get schemaVersion => 1;
}