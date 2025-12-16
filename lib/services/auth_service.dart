import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

/// Servicio de autenticación con WordPress JWT
class AuthService {
  static const String _baseUrl = 'https://wendystaufert.com/wp-json';
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';
  
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;

  /// Login con email y password
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/jwt-auth/v1/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        _token = data['token'];
        _currentUser = User(
          id: 0,
          email: data['user_email'] ?? email,
          displayName: data['user_display_name'] ?? '',
        );

        // Guardar en storage seguro
        await _storage.write(key: _tokenKey, value: _token);
        await _storage.write(key: _userKey, value: jsonEncode(_currentUser!.toJson()));

        return AuthResult.success(_currentUser!);
      } else {
        final error = jsonDecode(response.body);
        return AuthResult.error(error['message'] ?? 'Error de autenticación');
      }
    } catch (e) {
      return AuthResult.error('Error de conexión: $e');
    }
  }

  /// Logout
  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }

  /// Verificar sesión guardada
  Future<bool> checkSession() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      final userData = await _storage.read(key: _userKey);

      if (_token != null && userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        
        // Validar token con el servidor
        final isValid = await _validateToken();
        if (!isValid) {
          await logout();
          return false;
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Validar token con el servidor
  Future<bool> _validateToken() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/jwt-auth/v1/token/validate'),
        headers: {
          'Authorization': 'Bearer $_token',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Resultado de autenticación
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult._({required this.success, this.user, this.error});

  factory AuthResult.success(User user) => AuthResult._(success: true, user: user);
  factory AuthResult.error(String message) => AuthResult._(success: false, error: message);
}
