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
            color: Colors.blue.shade50,
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.map, size: 48, color: Color(0xFF1F6FB2)),
              SizedBox(height: 10),
              Text('Vue carte des recensements', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}