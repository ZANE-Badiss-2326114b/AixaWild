import 'package:flutter/material.dart';

import '../../widgets/intranet_appbar.dart';

class CarteIntranetPage extends StatelessWidget {
  const CarteIntranetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Carte'),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green.shade200),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map, size: 48, color: Colors.green),
              SizedBox(height: 10),
              Text('Vue carte des recensements', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}