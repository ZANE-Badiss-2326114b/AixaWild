import 'package:flutter/material.dart';

import '../../shared/navigation/app_routes.dart';
import '../../widgets/extranet_appbar.dart';

class LoginExtranetPage extends StatelessWidget {
  const LoginExtranetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: extranetAppBar(context, title: 'Connexion Extranet'),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildLoginButton(context),
          _buildCreateAccountButton(context),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return const TextField(
      decoration: InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField() {
    return const TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Mot de passe',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.intranetAccueil);
        },
        child: const Text('Se connecter'),
      ),
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.extranetSignIn);
      },
      child: const Text('Créer un compte'),
    );
  }
}
