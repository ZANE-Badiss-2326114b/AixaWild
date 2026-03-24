import 'package:flutter/material.dart';
import 'pages/auth/extranet_home_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/sign_in_page.dart';
import 'pages/intranet/accueil_page.dart';
import 'pages/intranet/carte_page.dart';
import 'pages/intranet/explication_page.dart';
import 'pages/intranet/formulaire_page.dart';
import 'pages/intranet/je_poste_page.dart';
import 'pages/intranet/messages_page.dart';
import 'pages/intranet/mes_fiches_page.dart';
import 'shared/navigation/app_routes.dart';

void main() {
  runApp(const AixaWildApp());
}

class AixaWildApp extends StatelessWidget {
  const AixaWildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AixaWild',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, primary: Colors.green[800]!),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.extranetHome,
      routes: {
        AppRoutes.intranetHome: (context) => const AccueilIntranetPage(),
        AppRoutes.intranetFormulaire: (context) => const FormulaireIntranetPage(),
        AppRoutes.intranetAccueil: (context) => const AccueilIntranetPage(),
        AppRoutes.intranetMesFiches: (context) => const MesFichesIntranetPage(),
        AppRoutes.intranetMessages: (context) => const MessagesIntranetPage(),
        AppRoutes.intranetJePoste: (context) => const JePosteIntranetPage(),
        AppRoutes.intranetCarte: (context) => const CarteIntranetPage(),
        AppRoutes.intranetExplication: (context) => const ExplicationIntranetPage(),
        AppRoutes.extranetHome: (context) => const HomeExtranetPage(),
        AppRoutes.extranetLogin: (context) => const LoginExtranetPage(),
        AppRoutes.extranetSignIn: (context) => const SignInExtranetPage(),
      },
    );
  }
}