import 'package:flutter/material.dart';

import '../../widgets/extranet_appbar.dart';

class SignInExtranetPage extends StatelessWidget {
  const SignInExtranetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: extranetAppBar(context, title: 'Inscription Extranet'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildNameField(),
          const SizedBox(height: 16),
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return const TextField(
      decoration: InputDecoration(
        labelText: 'Nom',
        border: OutlineInputBorder(),
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        child: const Text('S\'inscrire'),
      ),
    );
  }
}
