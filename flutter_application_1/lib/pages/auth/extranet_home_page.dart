import 'package:flutter/material.dart';

import '../../widgets/extranet_appbar.dart';

class HomeExtranetPage extends StatelessWidget {
  const HomeExtranetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: extranetAppBar(context, title: 'Accueil Extranet'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 8),
          _buildSubtitle(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Bienvenue sur l’extranet',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'Accédez rapidement à vos actions principales.',
      style: TextStyle(color: Colors.grey[700]),
    );
  }
}
