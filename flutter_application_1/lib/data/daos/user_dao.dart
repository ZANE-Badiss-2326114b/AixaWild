import 'package:drift/drift.dart';
import '../database/my_database.dart';
import '../models/user_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<MyDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  // Flux de données en temps réel pour l'UI
  Stream<List<User>> watchAllUsers() => select(users).watch();

  // Opérations de base
  Future<List<User>> getAllUsers() => select(users).get();
  
  Future<User?> getByEmail(String email) => 
      (select(users)..where((t) => t.email.equals(email))).getSingleOrNull();

  // Mise à jour ou insertion (Upsert)
  Future<void> upsertUser(UsersCompanion user) => 
      into(users).insertOnConflictUpdate(user);

  Future<void> deleteUser(String email) => 
      (delete(users)..where((t) => t.email.equals(email))).go();
}