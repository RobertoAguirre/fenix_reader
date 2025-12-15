import '../models/user.dart';

/// Servicio de autenticación
/// TODO: Implementar lógica de auth con WordPress
class AuthService {
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  /// Login con credenciales
  Future<User?> login(String email, String password) async {
    // TODO: Implementar llamada a WordPress API
    throw UnimplementedError();
  }

  /// Logout
  Future<void> logout() async {
    // TODO: Implementar logout
    throw UnimplementedError();
  }

  /// Verificar sesión guardada
  Future<bool> checkSession() async {
    // TODO: Implementar verificación de token guardado
    throw UnimplementedError();
  }
}

