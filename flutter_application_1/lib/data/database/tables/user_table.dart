import 'package:drift/drift.dart';

class Users extends Table {
	TextColumn get email => text()();
	TextColumn get username => text()();
	TextColumn get passwordHash => text()();
	TextColumn get typeName => text().nullable()();
	DateTimeColumn get createdAt => dateTime().nullable()();

	@override
	Set<Column<Object>> get primaryKey => {email};
}
