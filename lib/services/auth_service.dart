import 'dart:convert';
import 'package:flutter/foundation.dart';
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
      debugPrint('🔐 AuthService: Iniciando login para $email');
      
      // Codificar el body como URL-encoded (importante para passwords con caracteres especiales)
      final body = 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}';
      
      final response = await http.post(
        Uri.parse('$_baseUrl/jwt-auth/v1/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: body,
      );

      debugPrint('🔐 AuthService: Respuesta status=${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        _token = data['token'];
        _currentUser = User(
          id: 0,
          email: data['user_email'] ?? email,
          displayName: data['user_display_name'] ?? '',
        );

        debugPrint('✅ AuthService: Login exitoso para ${_currentUser?.email}');

        // Guardar en storage seguro
        await _storage.write(key: _tokenKey, value: _token);
        await _storage.write(key: _userKey, value: jsonEncode(_currentUser!.toJson()));

        debugPrint('✅ AuthService: Datos guardados en storage');

        return AuthResult.success(_currentUser!);
      } else {
        debugPrint('❌ AuthService: Error ${response.statusCode} - ${response.body}');
        final error = jsonDecode(response.body);
        return AuthResult.error(error['message'] ?? 'Error de autenticación');
      }
    } catch (e) {
      debugPrint('❌ AuthService: Excepción - $e');
      return AuthResult.error('Error de conexión: $e');
    }
  }

  /// Logout - Limpia completamente la sesión
  Future<void> logout() async {
    debugPrint('🚪 Iniciando logout...');
    
    // Limpiar en memoria
    _token = null;
    _currentUser = null;
    
    // Limpiar storage seguro
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
      debugPrint('✅ Storage limpiado correctamente');
    } catch (e) {
      debugPrint('⚠️ Error limpiando storage: $e');
    }
    
    // Limpiar todas las claves por si acaso
    try {
      await _storage.deleteAll();
      debugPrint('✅ Todo el storage limpiado');
    } catch (e) {
      debugPrint('⚠️ Error en deleteAll: $e');
    }
    
    debugPrint('✅ Logout completado');
  }

  /// Verificar sesión guardada
  Future<bool> checkSession() async {
    try {
      _token = await _storage.read(key: _tokenKey);
      final userData = await _storage.read(key: _userKey);

      debugPrint('🔍 Verificando sesión: token=${_token != null ? "existe" : "null"}, userData=${userData != null ? "existe" : "null"}');

      if (_token != null && userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        debugPrint('🔍 Usuario encontrado: ${_currentUser?.email}');
        
        // Validar token con el servidor
        debugPrint('🔍 Validando token con el servidor...');
        final isValid = await _validateToken();
        debugPrint('🔍 Token válido: $isValid');
        
        if (!isValid) {
          debugPrint('❌ Token inválido, limpiando sesión');
          await logout();
          return false;
        }
        debugPrint('✅ Sesión válida');
        return true;
      }
      debugPrint('❌ No hay sesión guardada');
      return false;
    } catch (e) {
      debugPrint('❌ Error verificando sesión: $e');
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
