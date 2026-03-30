import 'package:drift/drift.dart';
import '../database/my_database.dart';
import '../database/tables/user_table.dart';

part 'user_dao.g.dart';

@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<MyDatabase> with _$UserDaoMixin {
  UserDao(super.db);

  // Récupérer l'utilisateur local par son email
  Future<User?> getByEmail(String email) => 
      (select(users)..where((t) => t.email.equals(email))).getSingleOrNull();

  // Insérer ou mettre à jour le profil (Upsert)
  Future<void> upsertUser(UsersCompanion user) => 
      into(users).insertOnConflictUpdate(user);

  // Supprimer les données locales (Logout)
  Future<void> clearAll() => delete(users).go();
}