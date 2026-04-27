import 'package:flutter/foundation.dart';

import 'package:flutter_application_1/data/models/user.dart';
import 'package:flutter_application_1/data/repositories/user_repository.dart';

class AdminUserManagementProvider extends ChangeNotifier {
  AdminUserManagementProvider({required UserRepository userRepository})
      : _userRepository = userRepository;

  final UserRepository _userRepository;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<User> _users = <User>[];
  List<User> get users => List<User>.unmodifiable(_users);

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _users = await _userRepository.getAllUsers();
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createUser({
    required String email,
    required String username,
    required String password,
    String? typeName,
  }) async {
    bool isSuccess;

    _errorMessage = null;
    notifyListeners();

    try {
      final created = await _userRepository.createUser(
        email,
        username,
        password,
        typeName: typeName,
      );

      if (created != null) {
        await loadUsers();
        isSuccess = true;
      } else {
        _errorMessage = 'Création utilisateur impossible.';
        isSuccess = false;
      }
    } catch (error) {
      _errorMessage = error.toString();
      isSuccess = false;
    }

    notifyListeners();
    return isSuccess;
  }

  Future<User?> getUserProfile(String email) async {
    User? user;

    _errorMessage = null;
    notifyListeners();

    try {
      user = await _userRepository.getUserProfile(email);
    } catch (error) {
      _errorMessage = error.toString();
      user = null;
    }

    notifyListeners();
    return user;
  }

  Future<bool> deleteUser(String email) async {
    bool isSuccess;

    _errorMessage = null;
    notifyListeners();

    try {
      await _userRepository.deleteUserByEmail(email);
      await loadUsers();
      isSuccess = true;
    } catch (error) {
      _errorMessage = error.toString();
      isSuccess = false;
    }

    notifyListeners();
    return isSuccess;
  }
}
