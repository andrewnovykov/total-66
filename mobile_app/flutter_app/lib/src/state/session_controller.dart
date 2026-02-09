import 'package:flutter/foundation.dart';

import '../core/network/api_exception.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class SessionController extends ChangeNotifier {
  SessionController({required AuthService authService}) : _authService = authService;

  final AuthService _authService;

  AppUser? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.me();
    } on ApiException catch (error) {
      // Expected when app starts without an existing session cookie.
      if (error.statusCode != 401) {
        _errorMessage = error.message;
      }
      _currentUser = null;
    } catch (_) {
      _currentUser = null;
      _errorMessage = 'Unable to check current session';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(email: email, password: password);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _currentUser = null;
      return false;
    } catch (_) {
      _errorMessage = 'Login failed';
      _currentUser = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String username,
    required String email,
    required String password,
    String? bio,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(
        email: email,
        password: password,
        name: name,
        username: username,
        bio: bio,
      );
      _currentUser = await _authService.login(email: email, password: password);
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      _currentUser = null;
      return false;
    } catch (_) {
      _errorMessage = 'Registration failed';
      _currentUser = null;
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateCurrentUser(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (_) {
      // Clear local session even if server call fails.
    } finally {
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
    }
  }
}
