import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player_media_kit/video_player_media_kit.dart';
import 'pages/auth/extranet_home_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/sign_in_page.dart';
import 'pages/intranet/accueil_page.dart';
import 'pages/intranet/carte_page.dart';
import 'pages/intranet/explication_page.dart';
import 'pages/intranet/formulaire_page.dart';
import 'pages/intranet/test_posts_page.dart';
import 'pages/intranet/je_poste_page.dart';
import 'pages/intranet/messages_page.dart';
import 'pages/intranet/mes_fiches_page.dart';
import 'pages/intranet/recents_page.dart';
import 'pages/intranet/especes_page.dart';
import 'shared/navigation/app_routes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    VideoPlayerMediaKit.ensureInitialized(web: true);
  } else {
    VideoPlayerMediaKit.ensureInitialized(linux: true, windows: true, macOS: true, android: true, iOS: true);
  }
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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F6FB2), primary: const Color(0xFF1F6FB2)),
        primaryColor: const Color(0xFF1F6FB2),
        scaffoldBackgroundColor: const Color(0xFFECECEC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F6FB2),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1F6FB2),
            foregroundColor: Colors.white,
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.extranetLogin,
      routes: {
        AppRoutes.intranetHome: (context) => const AccueilIntranetPage(),
        AppRoutes.intranetFormulaire: (context) => const FormulaireIntranetPage(),
        AppRoutes.intranetAccueil: (context) => const AccueilIntranetPage(),
        AppRoutes.intranetTestPosts: (context) => const TestPostsPage(),
        AppRoutes.intranetMesFiches: (context) => const MesFichesIntranetPage(),
        AppRoutes.intranetRecents: (context) => const RecentsIntranetPage(),
        AppRoutes.intranetEspeces: (context) => const EspecesIntranetPage(),
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