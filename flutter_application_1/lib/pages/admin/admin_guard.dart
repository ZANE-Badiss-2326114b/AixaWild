import 'package:flutter/material.dart';

import 'package:flutter_application_1/data/api/auth/session_service.dart';
import 'package:flutter_application_1/data/models/user_identity.dart';
import 'package:flutter_application_1/shared/navigation/app_routes.dart';

class AdminGuard extends StatelessWidget {
  const AdminGuard({
    super.key,
    required this.child,
    this.redirectArguments,
  });

  final Widget child;
  final Object? redirectArguments;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserIdentity?>(
      future: SessionService().currentUser(),
      builder: (context, snapshot) {
        final identity = snapshot.data;
        final isAdmin = identity?.isAdmin ?? false;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.intranetAccueil,
                (route) => false,
                arguments: redirectArguments,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Accès refusé : Vous n\'avez pas les droits nécessaires'),
                ),
              );
            }
          });

          return const Scaffold(
            body: SizedBox.shrink(),
          );
        }

        return child;
      },
    );
  }
}
