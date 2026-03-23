import 'package:flutter/material.dart';

import '../../data/api/api_client.dart';
import '../../data/database/my_database.dart';
import '../../data/models/subscription_type.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/navigation/app_routes.dart';
import '../../widgets/extranet_appbar.dart';

class SignInExtranetPage extends StatefulWidget {
  const SignInExtranetPage({super.key});

  @override
  State<SignInExtranetPage> createState() => _SignInExtranetPageState();
}

class _SignInExtranetPageState extends State<SignInExtranetPage> {
  static final SubscriptionType _freeType = SubscriptionType(
    id: null,
    name: 'Free',
    description: 'Aucun abonnement',
  );

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final MyDatabase _database = MyDatabase();
  late final UserRepository _userRepository;
  late final SubscriptionRepository _subscriptionRepository;

  bool _isSubmitting = false;
  late Future<List<SubscriptionType>> _subscriptionTypesFuture;
  SubscriptionType _selectedType = _freeType;

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();
    _userRepository = UserRepository(apiClient, _database.userDao);
    _subscriptionRepository = SubscriptionRepository(apiClient);
    _subscriptionTypesFuture = _loadSubscriptionTypes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: extranetAppBar(context, title: 'Inscription Extranet'),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<List<SubscriptionType>>(
      future: _subscriptionTypesFuture,
      builder: (context, snapshot) {
        final options = snapshot.data ?? const <SubscriptionType>[];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildNameField(),
              const SizedBox(height: 16),
              _buildEmailField(),
              const SizedBox(height: 16),
              _buildPasswordField(),
              const SizedBox(height: 16),
              _buildSubscriptionDropdown(options),
              const SizedBox(height: 24),
              _buildSubmitButton(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNameField() {
    return TextField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Nom',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Mot de passe',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSubscriptionDropdown(List<SubscriptionType> options) {
    final allOptions = <SubscriptionType>[_freeType, ...options];

    final selectedValue = allOptions.any((type) =>
            type.id == _selectedType.id &&
            type.name.trim().toLowerCase() ==
                _selectedType.name.trim().toLowerCase())
        ? _selectedType
        : _freeType;

    return DropdownButtonFormField<SubscriptionType>(
      value: selectedValue,
      decoration: const InputDecoration(
        labelText: 'Abonnement',
        border: OutlineInputBorder(),
      ),
      items: allOptions.map((type) {
        final detail = type.id == null ? 'Aucun abonnement' : null;
        return DropdownMenuItem<SubscriptionType>(
          value: type,
          child: Text(detail == null ? type.name : '${type.name} ($detail)'),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _selectedType = value;
        });
      },
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : () => _onSignInPressed(context),
        child: _isSubmitting
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('S\'inscrire'),
      ),
    );
  }

  Future<List<SubscriptionType>> _loadSubscriptionTypes() async {
    final remoteTypes = await _subscriptionRepository.getAvailableTypes();
    return remoteTypes
        .where((type) => type.name.trim().toLowerCase() != 'free')
        .toList();
  }

  Future<void> _onSignInPressed(BuildContext context) async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Veuillez compléter tous les champs.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _userRepository.createUser(email, name, password);
      await _subscriptionRepository.createSubscriptionForUser(
        userEmail: email,
        selectedType: _selectedType,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.extranetLogin,
        arguments: email,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compte créé avec succès.')),
      );
    } catch (_) {
      _showMessage('Échec de l\'inscription, veuillez réessayer.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
