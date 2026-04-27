import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/data/api/core/dio_client.dart';
import 'package:flutter_application_1/data/database/my_database.dart';
import 'package:flutter_application_1/data/models/user.dart' as app_models;
import 'package:flutter_application_1/data/repositories/user_repository.dart';
import 'package:flutter_application_1/pages/admin/admin_guard.dart';
import 'package:flutter_application_1/pages/admin/providers/admin_user_management_provider.dart';
import 'package:flutter_application_1/widgets/intranet_appbar.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final MyDatabase _database = MyDatabase();
  late final AdminUserManagementProvider _provider;

  @override
  void initState() {
    super.initState();
    final apiClient = DioApiClient(
      onForbidden: (message) async {
        _showMessage(message);
      },
    );

    _provider = AdminUserManagementProvider(
      userRepository: UserRepository(apiClient, _database.userDao),
    );

    _provider.loadUsers();
  }

  @override
  void dispose() {
    _database.close();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routeArgument = ModalRoute.of(context)?.settings.arguments;

    return AdminGuard(
      redirectArguments: routeArgument,
      child: ChangeNotifierProvider<AdminUserManagementProvider>.value(
        value: _provider,
        child: Scaffold(
          appBar: intranetAppBar(title: 'Gestion des utilisateurs'),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCreateUserDialog,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Créer'),
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          body: Consumer<AdminUserManagementProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = provider.users;
              if (users.isEmpty) {
                return const Center(child: Text('Aucun utilisateur trouvé.'));
              }

              return RefreshIndicator(
                onRefresh: provider.loadUsers,
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: users.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(provider, user);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(AdminUserManagementProvider provider, app_models.User user) {
    return Card(
      child: ListTile(
        title: Text(user.username.isEmpty ? user.email : user.username),
        subtitle: Text(user.email),
        trailing: Wrap(
          spacing: 6,
          children: [
            IconButton(
              icon: const Icon(Icons.badge_outlined),
              tooltip: 'Voir profil',
              onPressed: () => _showUserProfile(provider, user.email),
            ),
            IconButton(
              icon: Icon(Icons.delete_forever, color: Colors.red.shade700),
              tooltip: 'Supprimer utilisateur',
              onPressed: () => _confirmDelete(provider, user.email),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUserProfile(AdminUserManagementProvider provider, String email) async {
    final profile = await provider.getUserProfile(email);

    if (!mounted) {
      return;
    }

    if (profile == null) {
      _showMessage(provider.errorMessage ?? 'Profil introuvable.');
    } else {
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Profil utilisateur'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Email: ${profile.email}'),
                const SizedBox(height: 6),
                Text('Nom: ${profile.username}'),
                const SizedBox(height: 6),
                Text('Type: ${profile.typeName ?? 'N/A'}'),
                const SizedBox(height: 6),
                Text('Créé le: ${profile.createdAt?.toIso8601String() ?? 'N/A'}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _confirmDelete(AdminUserManagementProvider provider, String email) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Supprimer l\'utilisateur $email ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      final success = await provider.deleteUser(email);
      if (!mounted) {
        return;
      }

      if (success) {
        _showMessage('Utilisateur supprimé.');
      } else {
        _showMessage(provider.errorMessage ?? 'Suppression impossible.');
      }
    }
  }

  Future<void> _openCreateUserDialog() async {
    final emailController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final typeController = TextEditingController();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Créer un utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Nom utilisateur'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                ),
                TextField(
                  controller: typeController,
                  decoration: const InputDecoration(labelText: 'Type (optionnel)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );

    if (shouldSubmit == true) {
      final provider = _provider;
      final success = await provider.createUser(
        email: emailController.text.trim(),
        username: usernameController.text.trim(),
        password: passwordController.text,
        typeName: typeController.text.trim().isEmpty ? null : typeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (success) {
        _showMessage('Utilisateur créé avec succès.');
      } else {
        _showMessage(provider.errorMessage ?? 'Création utilisateur impossible.');
      }
    }

    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    typeController.dispose();
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
