import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

/// Servicio de autenticación con WordPress JWT
class AuthService {
  static const String _baseUrl = 'https://wendystaufert.com/wp-json';
  static const String _customApiUrl = 'https://wendystaufert.com/wp-json/custom/v1';
  static const String _fenixApiUrl = 'https://wendystaufert.com/wp-json/fenix/v1';
  static const String _registerAppId = 'com.fenix.app.v1';
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';
  static const String _deviceIdKey = 'device_id';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  User? _currentUser;
  String? _token;
  String? _lastSessionInvalidReason;
  String? get sessionInvalidReason => _lastSessionInvalidReason;

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

        final deviceId = await _getOrCreateDeviceId();
        await _registerSession(deviceId);

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
      _lastSessionInvalidReason = null;
      _token = await _storage.read(key: _tokenKey);
      final userData = await _storage.read(key: _userKey);

      debugPrint('🔍 Verificando sesión: token=${_token != null ? "existe" : "null"}, userData=${userData != null ? "existe" : "null"}');

      if (_token != null && userData != null) {
        _currentUser = User.fromJson(jsonDecode(userData));
        debugPrint('🔍 Usuario encontrado: ${_currentUser?.email}');
        
        final isValidToken = await _validateToken();
        if (!isValidToken) {
          debugPrint('❌ Token inválido, limpiando sesión');
          await logout();
          return false;
        }

        final deviceId = await _getOrCreateDeviceId();
        final sessionValid = await _validateSession(deviceId);
        if (!sessionValid) {
          debugPrint('❌ Sesión en otro dispositivo, limpiando');
          _lastSessionInvalidReason = 'Tu cuenta está abierta en otro dispositivo. Inicia sesión de nuevo aquí.';
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

  Future<String> _getOrCreateDeviceId() async {
    String? id = await _storage.read(key: _deviceIdKey);
    if (id != null && id.isNotEmpty) return id;
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    id = base64UrlEncode(bytes).replaceAll('=', '');
    await _storage.write(key: _deviceIdKey, value: id);
    return id;
  }

  Future<void> _registerSession(String deviceId) async {
    if (_token == null) return;
    try {
      final response = await http.post(
        Uri.parse('$_fenixApiUrl/session/register'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'device_id': deviceId}),
      );
      if (response.statusCode != 200) debugPrint('⚠️ session/register: ${response.statusCode}');
    } catch (e) {
      debugPrint('⚠️ session/register: $e');
    }
  }

  Future<bool> _validateSession(String deviceId) async {
    if (_token == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_fenixApiUrl/session/validate'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'device_id': deviceId}),
      );
      if (response.statusCode != 200) return false;
      final data = jsonDecode(response.body);
      return data is Map && data['valid'] == true;
    } catch (e) {
      debugPrint('⚠️ session/validate: $e');
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

  /// Obtener credenciales de registro desde el backend
  Future<Map<String, String>> _getRegistrationCredentials() async {
    final response = await http.get(
      Uri.parse('$_customApiUrl/register-credentials'),
      headers: {
        'X-App-ID': _registerAppId,
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('No se pudieron obtener las credenciales de registro');
    }
    final data = jsonDecode(response.body);
    if (data is! Map || data['success'] != true) {
      throw Exception('No se pudieron obtener las credenciales de registro');
    }
    final endpoint = data['endpoint'] as String?;
    final apiKey = data['api_key'] as String?;
    if (endpoint == null || endpoint.isEmpty || apiKey == null || apiKey.isEmpty) {
      throw Exception('No se pudieron obtener las credenciales de registro');
    }
    return {'endpoint': endpoint, 'api_key': apiKey};
  }

  static String _stripHtml(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .trim();
  }

  /// Mensaje de error neutro para el usuario (sin referencias a ventas)
  static String _mapRegisterError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('email ya está registrado') || lower.contains('usuario o email ya existe')) {
      return 'El correo ya está registrado. Inicia sesión o usa otro correo.';
    }
    if (lower.contains('contraseña') && lower.contains('8')) {
      return 'La contraseña debe tener al menos 8 caracteres.';
    }
    if (lower.contains('email inválido') || lower.contains('invalid email')) {
      return 'El formato del correo no es válido.';
    }
    if (lower.contains('faltan campos')) {
      return 'Completa todos los campos requeridos.';
    }
    if (lower.contains('origen no permitido') || lower.contains('no autorizado')) {
      return 'Acceso no autorizado.';
    }
    if (lower.contains('api key') || lower.contains('autenticación')) {
      return 'Error de conexión. Inténtalo más tarde.';
    }
    if (lower.contains('demasiados intentos') || lower.contains('rate limit')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    return _stripHtml(message).isEmpty ? 'Error al crear la cuenta. Inténtalo de nuevo.' : _stripHtml(message);
  }

  /// Registro de usuario nuevo (mismo backend que FenixRn)
  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      debugPrint('🔐 AuthService: Obteniendo credenciales de registro');
      final credentials = await _getRegistrationCredentials();
      final endpoint = credentials['endpoint']!;
      final apiKey = credentials['api_key']!;

      final body = jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      });

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'X-API-Key': apiKey,
          'X-App-ID': _registerAppId,
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data['success'] == true) {
          debugPrint('✅ AuthService: Registro exitoso');
          return AuthResult.success(User(id: 0, email: email, displayName: '$firstName $lastName'));
        }
      }

      String errorMessage = response.body;
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      } catch (_) {}
      errorMessage = _stripHtml(errorMessage);
      final lower = errorMessage.toLowerCase();

      if (lower.contains('ya existe') || lower.contains('already exists')) {
        try {
          debugPrint('🔐 AuthService: Intentando convertir invitado');
          final convertResponse = await http.post(
            Uri.parse('$_fenixApiUrl/convertir-invitado'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': password,
              'first_name': firstName,
              'last_name': lastName,
            }),
          );
          if (convertResponse.statusCode == 200) {
            final convertData = jsonDecode(convertResponse.body);
            if (convertData is Map && convertData['success'] == true) {
              debugPrint('✅ AuthService: Cuenta convertida exitosamente');
              return AuthResult.success(User(id: 0, email: email, displayName: '$firstName $lastName'));
            }
          }
        } catch (e) {
          debugPrint('❌ AuthService: Error convertir invitado: $e');
        }
      }

      return AuthResult.error(_mapRegisterError(errorMessage));
    } catch (e) {
      debugPrint('❌ AuthService: Excepción en registro: $e');
      return AuthResult.error('Error de conexión. Inténtalo de nuevo.');
    }
  }

  /// Solicitar recuperación de contraseña (mismo endpoint que FenixRn: wp-login.php?action=lostpassword)
  Future<void> requestPasswordReset(String email) async {
    final uri = Uri.parse('https://wendystaufert.com/wp-login.php?action=lostpassword');
    final body = 'user_login=${Uri.encodeComponent(email)}&redirect_to=&wp-submit=Get+New+Password';
    final response = await http.post(
      uri,
      headers: {
        'User-Agent': 'Flutter/FenixReader',
        'Origin': 'https://wendystaufert.com',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );
    if (response.statusCode == 404) {
      throw Exception('No existe una cuenta con ese correo electrónico');
    }
    if (response.statusCode == 429) {
      throw Exception('Demasiados intentos. Intenta de nuevo en unos minutos');
    }
    if (response.statusCode >= 400) {
      throw Exception('Error al procesar la solicitud. Intenta de nuevo');
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
