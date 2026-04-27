import 'package:flutter/material.dart';

import '../shared/navigation/app_routes.dart';

class IntranetNavigationDrawer extends StatelessWidget {
  const IntranetNavigationDrawer({
    super.key,
    required this.currentEmail,
    required this.isAdmin,
    required this.onOpenAdministration,
  });

  final String currentEmail;
  final bool isAdmin;
  final VoidCallback onOpenAdministration;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('Navigation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home_outlined),
              title: const Text('Accueil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.intranetAccueil, arguments: currentEmail);
              },
            ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Accueil Admin'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.adminDashboard, arguments: currentEmail);
                },
              ),
            if (isAdmin)
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Administration'),
                onTap: () {
                  Navigator.pop(context);
                  onOpenAdministration();
                },
              ),
          ],
        ),
      ),
    );
  }
}
