import 'package:flutter/material.dart';

import '../../data/api/auth/auth_token_manager.dart';
import '../../data/api/core/dio_client.dart';
import '../../data/database/my_database.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/navigation/app_routes.dart';
import '../../widgets/extranet_appbar.dart';

class LoginExtranetPage extends StatefulWidget {
  const LoginExtranetPage({super.key});

  @override
  State<LoginExtranetPage> createState() => _LoginExtranetPageState();
}

class _LoginExtranetPageState extends State<LoginExtranetPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final MyDatabase _database = MyDatabase();
  late final UserRepository _userRepository;

  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository(DioApiClient(), _database.userDao);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;

    final routeArgument = ModalRoute.of(context)?.settings.arguments;
    if (routeArgument is String && routeArgument.trim().isNotEmpty) {
      _emailController.text = routeArgument.trim();
    }

    _isInitialized = true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: extranetAppBar(context, title: 'Connexion Extranet'),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [const SizedBox(height: 20), _buildEmailField(_emailController), const SizedBox(height: 16), _buildPasswordField(_passwordController), const SizedBox(height: 24), _buildLoginButton(context), _buildCreateAccountButton(context)]),
    );
  }

  Widget _buildEmailField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
    );
  }

  Widget _buildPasswordField(TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: const InputDecoration(labelText: 'Mot de passe', border: OutlineInputBorder()),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : () => _onLoginPressed(context),
        child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Se connecter'),
      ),
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.extranetSignIn);
      },
      child: const Text('Créer un compte'),
    );
  }

  Future<void> _onLoginPressed(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Veuillez renseigner email et mot de passe.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    bool isAuthenticated;
    String? loginError;

    try {
      final syncedUser = await _userRepository.loginAndSync(email, password);
      isAuthenticated = syncedUser != null;
    } catch (error) {
      isAuthenticated = false;
      loginError = error.toString();
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    if (!isAuthenticated) {
      await AuthTokenManager.instance.clearToken();
      if (loginError != null && loginError.isNotEmpty) {
        _showMessage('Connexion impossible: $loginError');
      } else {
        _showMessage('Connexion impossible: identifiants invalides.');
      }
      return;
    }

    Navigator.pushReplacementNamed(context, AppRoutes.intranetAccueil, arguments: email);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
