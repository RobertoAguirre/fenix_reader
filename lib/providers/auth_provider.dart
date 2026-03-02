import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Provider de autenticación
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? get user => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  /// Inicializar - verificar sesión guardada
  Future<bool> init() async {
    _isLoading = true;
    notifyListeners();

    final hasSession = await _authService.checkSession();
    if (!hasSession) {
      final reason = _authService.sessionInvalidReason;
      if (reason != null) _error = reason;
    }

    _isLoading = false;
    notifyListeners();

    return hasSession;
  }

  /// Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    _isLoading = false;
    
    if (result.success) {
      _error = null;
    } else {
      _error = result.error;
    }
    
    notifyListeners();
    return result.success;
  }

  /// Registro de usuario nuevo
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      username: username,
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    _isLoading = false;
    if (result.success) {
      _error = null;
    } else {
      _error = result.error;
    }
    notifyListeners();
    return result.success;
  }

  /// Logout - Limpia autenticación y notifica
  Future<void> logout() async {
    debugPrint('🚪 AuthProvider: Iniciando logout');
    await _authService.logout();
    _error = null;
    _isLoading = false;
    notifyListeners();
    debugPrint('✅ AuthProvider: Logout completado');
  }

  /// Solicitar recuperación de contraseña (enlace al correo)
  Future<void> requestPasswordReset(String email) async {
    await _authService.requestPasswordReset(email);
  }

  /// Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
