import 'package:flutter/material.dart';

import '../shared/navigation/app_routes.dart';

Widget intranetBottomNavigationBar(
  BuildContext context, {
  required String selectedTab,
}) {
  final currentRoute = ModalRoute.of(context)?.settings.name;
  final currentArguments = ModalRoute.of(context)?.settings.arguments;

  return Container(
    color: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _navItems.map((item) {
          final isSelected = item.label == selectedTab;
          final isDisabled = item.routeName == null || item.routeName == currentRoute;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(item.label, style: const TextStyle(fontSize: 12)),
              onSelected: isDisabled
                  ? null
                  : (_) {
                      Navigator.pushReplacementNamed(
                        context,
                        item.routeName!,
                        arguments: currentArguments,
                      );
                    },
              selectedColor: Colors.blue[700],
              backgroundColor: Colors.blue[100],
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.blue[900],
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    ),
  );
}

const List<_NavItem> _navItems = [
  _NavItem('Accueil', AppRoutes.intranetAccueil),
  _NavItem('Mes fiches', AppRoutes.intranetMesFiches),
  _NavItem('Récents', AppRoutes.intranetRecents),
  _NavItem('Espèces', AppRoutes.intranetEspeces),
  _NavItem('Messages', AppRoutes.intranetMessages),
  _NavItem('Je poste', AppRoutes.intranetJePoste),
  _NavItem('Carte', AppRoutes.intranetCarte),
  _NavItem('Explication', AppRoutes.intranetExplication),
  _NavItem('Contributeur', null),
];

class _NavItem {
  const _NavItem(this.label, this.routeName);

  final String label;
  final String? routeName;
}