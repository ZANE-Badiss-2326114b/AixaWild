import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/api/api_client.dart';
import 'data/database/my_database.dart';
import 'data/repositories/user_repository.dart';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aixawild',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const Scaffold(
        body: Center(child: Text("Architecture prête !")),
      ),
    );
  }
}
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation des composants de base
  final database = MyDatabase();
  final apiClient = ApiClient();
  
  // 2. Initialisation du Repository
  final userRepository = UserRepository(apiClient, database.userDao);

  runApp(
    MultiProvider(
      providers: [
        // On injecte la DB au cas où on en aurait besoin ailleurs
        Provider<MyDatabase>.value(value: database),
        // On injecte le Repository : c'est lui que l'UI appellera
        Provider<UserRepository>.value(value: userRepository),
      ],
      child: const MyApp(),
    ),
  );
}