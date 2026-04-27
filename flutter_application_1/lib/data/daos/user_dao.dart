import 'package:drift/drift.dart';
import 'package:flutter_application_1/data/database/my_database.dart';
import 'package:flutter_application_1/data/database/tables/user_table.dart';

part 'user_dao.g.dart';

/// DAO Drift pour la projection locale des utilisateurs.
///
/// Ce composant encapsule les opérations SQL basiques utilisées par le
/// repository utilisateur.
@DriftAccessor(tables: [Users])
class UserDao extends DatabaseAccessor<MyDatabase> with _$UserDaoMixin {
  /// Construit le DAO utilisateur.
  ///
  /// [db] est la base Drift attachée.
  UserDao(super.db);

  /// Récupère un utilisateur local par email.
  ///
  /// [email] identifie la ligne recherchée.
  /// Retourne un [User] Drift ou `null` si absent.
  Future<User?> getByEmail(String email) => (select(users)..where((t) => t.email.equals(email))).getSingleOrNull();

  /// Insère ou met à jour un profil utilisateur.
  ///
  /// [user] contient les valeurs à persister.
  /// Retourne `Future<void>`.
  Future<void> upsertUser(UsersCompanion user) => into(users).insertOnConflictUpdate(user);

  /// Supprime tous les utilisateurs locaux.
  ///
  /// Retourne `Future<void>`.
  Future<void> clearAll() => delete(users).go();
}
