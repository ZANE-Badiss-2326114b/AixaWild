import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final UserRepository _userRepository;

  static const String _rememberMeKey = 'remember_me';
  static const String _rememberedEmailKey = 'remembered_email';

  bool _isLoading = false;
  bool _isInitialized = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _userRepository = UserRepository(DioApiClient(), _database.userDao);
    _loadRememberedLogin();
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
      backgroundColor: const Color(0xFFECECEC),
      appBar: extranetAppBar(context, title: 'Connexion Extranet'),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD8D8D8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 18),
                _buildEmailField(_emailController),
                const SizedBox(height: 10),
                _buildPasswordField(_passwordController),
                const SizedBox(height: 10),
                _buildRememberAndForgotRow(),
                const SizedBox(height: 14),
                _buildLoginButton(context),
                const SizedBox(height: 14),
                _buildSeparator(),
                const SizedBox(height: 12),
                _buildSocialRow(),
                const SizedBox(height: 8),
                _buildCreateAccountButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: const [
        Text(
          'Bienvenue sur AixaWild',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B1B1B),
          ),
        ),
        SizedBox(height: 14),
        CircleAvatar(
          radius: 34,
          backgroundColor: Color(0xFFE9EEF5),
          child: Icon(Icons.person, size: 44, color: Color(0xFF1F2937)),
        ),
      ],
    );
  }

  Widget _buildEmailField(TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: _inputDecoration('Email'),
    );
  }

  Widget _buildPasswordField(TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: _inputDecoration('Password'),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xFFB6B6B6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xFFB6B6B6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(2),
        borderSide: const BorderSide(color: Color(0xFF1F6FB2), width: 1.3),
      ),
    );
  }

  Widget _buildRememberAndForgotRow() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _rememberMe,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (value) {
              setState(() {
                _rememberMe = value ?? false;
              });
            },
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            setState(() {
              _rememberMe = !_rememberMe;
            });
          },
          child: const Text('Enregistrer', style: TextStyle(fontSize: 12)),
        ),
        const Spacer(),
        TextButton(
          style: TextButton.styleFrom(
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: _isLoading ? null : _onForgotPasswordPressed,
          child: const Text('Mot de passe oublié ?', style: TextStyle(fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F6FB2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
        onPressed: _isLoading ? null : _onLoginPressed,
        child: _isLoading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('LOGIN'),
      ),
    );
  }

  Widget _buildSeparator() {
    return const Text(
      '----------OU----------',
      style: TextStyle(
        color: Color(0xFF616161),
        fontSize: 12,
      ),
    );
  }

  Widget _buildSocialRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFFE53935),
          child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        SizedBox(width: 12),
        CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFF1877F2),
          child: Text('f', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
        SizedBox(width: 12),
        CircleAvatar(
          radius: 14,
          backgroundColor: Color(0xFF0A66C2),
          child: Text('in', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF121212)),
      onPressed: () {
        Navigator.pushNamed(context, AppRoutes.extranetSignIn);
      },
      child: const Text(
        'Créer ton compte ?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _onLoginPressed() async {
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

    await _saveRememberPreference(email);

    Navigator.pushReplacementNamed(context, AppRoutes.intranetAccueil, arguments: email);
  }

  Future<void> _onForgotPasswordPressed() async {
    final initialEmail = _emailController.text.trim();
    final dialogController = TextEditingController(text: initialEmail);

    final enteredEmail = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Réinitialiser le mot de passe'),
          content: TextField(
            controller: dialogController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, dialogController.text.trim()),
              child: const Text('Envoyer'),
            ),
          ],
        );
      },
    );

    dialogController.dispose();

    if (enteredEmail == null || enteredEmail.isEmpty) {
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(enteredEmail)) {
      _showMessage('Veuillez entrer une adresse email valide.');
      return;
    }

    try {
      await _userRepository.requestPasswordReset(enteredEmail);
      if (!mounted) return;
      _showMessage('Si le compte existe, un email de réinitialisation a été envoyé.');
    } catch (_) {
      if (!mounted) return;
      _showMessage('Impossible d\'envoyer la demande pour le moment. Réessaie plus tard.');
    }
  }

  Future<void> _loadRememberedLogin() async {
    final rememberValue = await _storage.read(key: _rememberMeKey);
    if (rememberValue != 'true') {
      return;
    }

    final rememberedEmail = (await _storage.read(key: _rememberedEmailKey))?.trim();
    if (!mounted) return;

    setState(() {
      _rememberMe = true;
      if (rememberedEmail != null && rememberedEmail.isNotEmpty) {
        _emailController.text = rememberedEmail;
      }
    });
  }

  Future<void> _saveRememberPreference(String email) async {
    if (_rememberMe) {
      await _storage.write(key: _rememberMeKey, value: 'true');
      await _storage.write(key: _rememberedEmailKey, value: email);
      return;
    }

    await _storage.delete(key: _rememberMeKey);
    await _storage.delete(key: _rememberedEmailKey);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
