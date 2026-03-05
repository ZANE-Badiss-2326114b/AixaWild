import 'package:flutter/material.dart';

import '../../shared/navigation/app_routes.dart';
import '../../widgets/intranet_appbar.dart';

class FormulaireIntranetPage extends StatefulWidget {
  const FormulaireIntranetPage({super.key});

  @override
  State<FormulaireIntranetPage> createState() => _FormulaireIntranetPageState();
}

class _FormulaireIntranetPageState extends State<FormulaireIntranetPage> {
  final _nomController = TextEditingController();
  String _categorie = 'Faune';

  String _sanitizeInput(String input) {
    final buffer = StringBuffer();
    final allowed = RegExp(r'[a-zA-Z0-9\s\-éèêëàâäùûüôöçœæ]');

    for (final char in input.split('')) {
      if (allowed.hasMatch(char)) {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  void _enregistrerObservation() {
    if (_nomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer un nom d\'espèce')),
      );
      return;
    }

    if (!_isValidInput(_nomController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caractères non autorisés détectés')),
      );
      return;
    }

    final dateActuelle = DateTime.now();
    debugPrint(
      'Enregistré le : ${dateActuelle.day}/${dateActuelle.month} à ${dateActuelle.hour}:${dateActuelle.minute}, Observation : ${_nomController.text} ($_categorie)',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_nomController.text} enregistré avec succès !')),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.intranetHome,
      (Route<dynamic> route) => false,
    );
  }

  bool _isValidInput(String input) {
    final regex = RegExp(r'^[a-zA-Z0-9\s\-éèêëàâäùûüôöçœæ]+$');
    return regex.hasMatch(input);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Recensement'),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(),
          const SizedBox(height: 10),
          _buildSpeciesField(),
          const SizedBox(height: 25),
          _buildCategorySelector(),
          const Spacer(),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Quelle espèce avez-vous vue ?',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSpeciesField() {
    return TextField(
      controller: _nomController,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        hintText: 'Ex: Sanglier, Olivier, Cigale...',
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: _onSpeciesChanged,
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Catégorie :', style: TextStyle(fontSize: 16)),
        DropdownButton<String>(
          value: _categorie,
          isExpanded: true,
          items: <String>['Faune', 'Flore'].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (nouvelleValeur) {
            setState(() {
              _categorie = nouvelleValeur!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _enregistrerObservation,
        icon: const Icon(Icons.check),
        label: const Text('Enregistrer l\'observation'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  void _onSpeciesChanged(String value) {
    final filtered = _sanitizeInput(value);
    if (filtered != value) {
      _nomController.text = filtered;
      _nomController.selection = TextSelection.fromPosition(
        TextPosition(offset: filtered.length),
      );
    }
  }
}
