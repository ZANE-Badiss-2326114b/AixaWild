import 'package:drift/drift.dart';

/// Définition de la table locale `users`.
///
/// Cette table sert de cache utilisateur pour l'authentification offline et la
/// conservation minimale du profil.
class Users extends Table {
  /// Email utilisateur (clé primaire fonctionnelle).
  TextColumn get email => text()();

  /// Nom d'affichage.
  TextColumn get username => text()();

  /// Mot de passe hashé/stocké localement pour fallback offline.
  TextColumn get passwordHash => text()();

  /// Type d'abonnement associé au profil.
  TextColumn get typeName => text().nullable()();

  /// Date de création côté backend si disponible.
  DateTimeColumn get createdAt => dateTime().nullable()();

  @override
  /// Clé primaire Drift.
  ///
  /// Retourne l'ensemble des colonnes constituant la PK.
  Set<Column<Object>> get primaryKey => {email};
}
