import 'package:drift/drift.dart';

class Users extends Table {
  TextColumn get email => text().named('user_email').withLength(min: 1, max: 100)();
  TextColumn get username => text().withLength(min: 1, max: 50)();
  TextColumn get passwordHash => text().named('password_hash')();
  DateTimeColumn get createdAt => dateTime().named('created_at').withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {email};
}