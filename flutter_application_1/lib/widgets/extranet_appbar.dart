import 'package:flutter/material.dart';

import '../shared/navigation/app_routes.dart';

PreferredSizeWidget extranetAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
}) {
  final routeName = ModalRoute.of(context)?.settings.name;

  return AppBar(
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
    centerTitle: true,
    backgroundColor: const Color(0xFF1F6FB2),
    foregroundColor: Colors.white,
    actions: actions ?? _buildDefaultActions(context, routeName),
  );
}

List<Widget> _buildDefaultActions(BuildContext context, String? routeName) {
  return [
    _buildNavAction(
      context: context,
      routeName: routeName,
      targetRoute: AppRoutes.extranetHome,
      icon: Icons.home_outlined,
      tooltip: 'Accueil',
    ),
    _buildNavAction(
      context: context,
      routeName: routeName,
      targetRoute: AppRoutes.extranetLogin,
      icon: Icons.login,
      tooltip: 'Connexion',
    ),
    _buildNavAction(
      context: context,
      routeName: routeName,
      targetRoute: AppRoutes.extranetSignIn,
      icon: Icons.person_add_alt_1,
      tooltip: 'Inscription',
    ),
    const SizedBox(width: 8),
  ];
}

Widget _buildNavAction({
  required BuildContext context,
  required String? routeName,
  required String targetRoute,
  required IconData icon,
  required String tooltip,
}) {
  return IconButton(
    tooltip: tooltip,
    onPressed: routeName == targetRoute
        ? null
        : () {
            Navigator.pushReplacementNamed(context, targetRoute);
          },
    icon: Icon(icon),
  );
}
