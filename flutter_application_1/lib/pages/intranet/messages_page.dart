import 'package:flutter/material.dart';

import '../../widgets/intranet_bottom_navigation.dart';
import '../../widgets/intranet_appbar.dart';

class MessagesIntranetPage extends StatelessWidget {
  const MessagesIntranetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: intranetAppBar(title: 'AixaWild - Messages'),
      bottomNavigationBar: intranetBottomNavigationBar(context, selectedTab: 'Messages'),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          return ListTile(
            tileColor: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const CircleAvatar(child: Icon(Icons.message)),
            title: Text('Message ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Nouveau recensement disponible.'),
            trailing: const Icon(Icons.chevron_right),
          );
        },
      ),
    );
  }
}