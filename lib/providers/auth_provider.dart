import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider de autenticación
/// TODO: Implementar lógica cuando auth_service esté listo
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? get user => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> login(String email, String password) async {
    // TODO: Implementar
  }

  Future<void> logout() async {
    // TODO: Implementar
  }
}

