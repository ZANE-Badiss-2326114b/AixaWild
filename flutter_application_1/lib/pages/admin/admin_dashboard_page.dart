import 'package:flutter/material.dart';

import 'package:flutter_application_1/pages/admin/admin_guard.dart';
import 'package:flutter_application_1/shared/navigation/app_routes.dart';
import 'package:flutter_application_1/widgets/intranet_appbar.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final routeArgument = ModalRoute.of(context)?.settings.arguments;

    return AdminGuard(
      redirectArguments: routeArgument,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: intranetAppBar(title: 'Administration'),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Accueil Admin', icon: Icon(Icons.dashboard_outlined)),
                    Tab(text: 'Gestion Utilisateurs', icon: Icon(Icons.group)),
                    Tab(text: 'Monitoring Posts', icon: Icon(Icons.monitor_heart)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TabBarView(
                    children: [
                      _AdminHomeTab(routeArgument: routeArgument),
                      _AdminEntryCard(
                        title: 'Gestion des utilisateurs',
                        subtitle: 'Lister, créer, consulter et supprimer des utilisateurs',
                        icon: Icons.group,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.adminUserManagement,
                            arguments: routeArgument,
                          );
                        },
                      ),
                      _AdminEntryCard(
                        title: 'Monitoring des publications',
                        subtitle: 'Surveiller engagement, signalements et modération',
                        icon: Icons.monitor_heart,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.adminPostMonitoring,
                            arguments: routeArgument,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminHomeTab extends StatelessWidget {
  const _AdminHomeTab({required this.routeArgument});

  final Object? routeArgument;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Accueil Administrateur', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('Accès rapide aux outils de supervision et de modération de la plateforme.'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _AdminEntryCard(
          title: 'Gestion des utilisateurs',
          subtitle: 'Ouvrir le module utilisateurs',
          icon: Icons.group,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.adminUserManagement,
              arguments: routeArgument,
            );
          },
        ),
        const SizedBox(height: 12),
        _AdminEntryCard(
          title: 'Monitoring des publications',
          subtitle: 'Ouvrir le module de modération des posts',
          icon: Icons.monitor_heart,
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.adminPostMonitoring,
              arguments: routeArgument,
            );
          },
        ),
      ],
    );
  }
}

class _AdminEntryCard extends StatelessWidget {
  const _AdminEntryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.shade100,
          child: Icon(icon, color: Colors.red.shade700),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
