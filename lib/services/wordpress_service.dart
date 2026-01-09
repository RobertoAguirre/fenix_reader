import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cache_service.dart';

/// Servicio para consumir WordPress REST API
class WordPressService {
  static const String baseUrl = 'https://wendystaufert.com/wp-json/fenix/v1';
  static const String wpBaseUrl = 'https://wendystaufert.com/wp-json/wp/v2';
  
  // Timeouts
  static const Duration normalTimeout = Duration(seconds: 10);
  static const Duration slowTimeout = Duration(seconds: 30);
  
  // Headers estándar
  static Map<String, String> get _defaultHeaders => {
    'User-Agent': 'Flutter/FenixReader',
    'Origin': 'https://wendystaufert.com',
    'Content-Type': 'application/json',
  };

  final CacheService _cacheService = CacheService();

  /// Retry con backoff exponencial para peticiones HTTP
  Future<T> _retryWithBackoff<T>(
    Future<T> Function() fn, {
    int maxRetries = 2,
  }) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        return await fn();
      } catch (e) {
        // Si es el último intento, lanzar el error
        if (i == maxRetries - 1) rethrow;

        // Verificar si es error de red o timeout
        final isNetworkError = e.toString().contains('TimeoutException') ||
            e.toString().contains('SocketException') ||
            e.toString().contains('timeout') ||
            e.toString().contains('Network');

        if (isNetworkError) {
          debugPrint('🔄 Reintentando petición (${i + 1}/$maxRetries)...');
          // Esperar 1s, 2s, 4s... (backoff exponencial)
          await Future.delayed(Duration(seconds: (1 << i)));
        } else {
          // Si es error del servidor (4xx, 5xx), no reintentar
          rethrow;
        }
      }
    }
    throw Exception('Retry failed');
  }

  /// Obtener contenido del usuario (adquirido en web externa)
  Future<UserContent> getUserContent(String email, {bool forceRefresh = false}) async {
    debugPrint('📦 Obteniendo contenido del usuario: $email');

    final purchases = await _getUserPurchases(email, forceRefresh: forceRefresh);

    final content = UserContent(purchases: purchases);

    _logContent(content);
    return content;
  }

  /// Obtener contenido del usuario (adquirido en web externa)
  Future<List<ContentItem>> _getUserPurchases(String email, {bool forceRefresh = false}) async {
    // Verificar caché si no se fuerza refresh
    if (!forceRefresh) {
      final cached = await _cacheService.getCachedPurchases(email);
      if (cached != null) {
        debugPrint('✅ Contenido desde caché: ${cached.length} items');
        return cached.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      }
    }

    // Verificar rate limiting
    final shouldThrottle = await _cacheService.checkRateLimit('purchases');
    if (shouldThrottle && !forceRefresh) {
      final cached = await _cacheService.getCachedPurchases(email);
      if (cached != null) {
        debugPrint('⚠️ Rate limit: usando caché');
        return cached.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      }
    }

    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/user-purchases?email=${Uri.encodeComponent(email)}'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        List<dynamic> data;
        if (decoded is List) {
          data = decoded;
        } else if (decoded is Map<String, dynamic>) {
          data = decoded['purchases'] as List<dynamic>? ??
                 decoded['items'] as List<dynamic>? ??
                 decoded['data'] as List<dynamic>? ??
                 [];
        } else {
          data = [];
        }
        
        // Guardar en caché
        await _cacheService.saveCachedPurchases(email, data);
        
        debugPrint('✅ Contenido del usuario: ${data.length} items');
        
        // Debug: mostrar campos disponibles en el primer item
        if (data.isNotEmpty) {
          final firstItem = data.first as Map<String, dynamic>;
          debugPrint('📋 Campos disponibles en el primer item:');
          firstItem.keys.forEach((key) {
            final value = firstItem[key];
            debugPrint('  - $key: ${value != null ? (value.toString().length > 100 ? value.toString().substring(0, 100) + '...' : value.toString()) : 'null'}');
          });
        }
        
        return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        debugPrint('⚠️ Error obteniendo contenido: ${response.statusCode}');
        // Intentar usar caché como fallback
        final cached = await _cacheService.getCachedPurchases(email);
        if (cached != null) {
          return cached.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
        }
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error obteniendo contenido del usuario: $e');
      // Intentar usar caché como fallback
      final cached = await _cacheService.getCachedPurchases(email);
      if (cached != null) {
        debugPrint('⚠️ Usando caché como fallback');
        return cached.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    }
  }

  /// Log del contenido obtenido
  void _logContent(UserContent content) {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════');
    debugPrint('📱 MI CONTENIDO');
    debugPrint('═══════════════════════════════════════════');
    
    debugPrint('');
    debugPrint('📚 TODO (${content.all.length}):');
    for (final item in content.all) {
      debugPrint('  • ${item.title} [${item.type.name}]');
    }

    debugPrint('');
    debugPrint('🌀 HIPNOSIS (${content.hypnosis.length}):');
    for (final item in content.hypnosis) {
      debugPrint('  • ${item.title}');
    }

    debugPrint('');
    debugPrint('🧘 MEDITACIONES (${content.meditations.length}):');
    for (final item in content.meditations) {
      debugPrint('  • ${item.title}');
    }

    debugPrint('');
    debugPrint('═══════════════════════════════════════════');
  }

  // ============================================
  // ENDPOINTS DE CONTENIDO POR TIPO
  // ============================================

  /// Obtener meditaciones del usuario
  Future<List<ContentItem>> getUserMeditaciones(String email) async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/meditaciones?email=${Uri.encodeComponent(email)}'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is List ? decoded : [];
        return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo meditaciones: $e');
      return [];
    }
  }

  /// Obtener hipnosis del usuario
  Future<List<ContentItem>> getUserHipnosis(String email) async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/hipnosis?email=${Uri.encodeComponent(email)}'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is List ? decoded : [];
        return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo hipnosis: $e');
      return [];
    }
  }

  /// Obtener hipnosis por nivel de acceso
  Future<List<ContentItem>> getUserHipnosisMembresia(String email) async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/hipnosis-membresia?email=${Uri.encodeComponent(email)}'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is List ? decoded : [];
        return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo hipnosis por nivel: $e');
      return [];
    }
  }

  /// Obtener meditaciones públicas
  Future<List<ContentItem>> getPublicMeditaciones() async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/meditaciones-publicas?t=${DateTime.now().millisecondsSinceEpoch}'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is List ? decoded : [];
        return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo meditaciones públicas: $e');
      return [];
    }
  }

  /// Obtener hipnosis públicas
  Future<List<ContentItem>> getPublicHipnosis() async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/hipnosis-publicas?t=${DateTime.now().millisecondsSinceEpoch}'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final data = decoded is List ? decoded : [];
        return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo hipnosis públicas: $e');
      return [];
    }
  }

  // ============================================
  // ENDPOINTS DE NIVELES DE ACCESO
  // ============================================

  /// Obtener niveles de acceso activos del usuario
  Future<List<Map<String, dynamic>>> getUserMemberships(String email) async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/user-memberships?email=${Uri.encodeComponent(email)}'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is List ? List<Map<String, dynamic>>.from(decoded) : [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo niveles de acceso: $e');
      return [];
    }
  }

  /// Obtener todos los niveles de acceso disponibles
  Future<List<Map<String, dynamic>>> getAllMemberships({bool forceRefresh = false}) async {
    // Verificar caché si no se fuerza refresh
    if (!forceRefresh) {
      final isCacheValid = await _cacheService.isMembershipsCacheValid();
      if (isCacheValid) {
        final cached = await _cacheService.getCachedMemberships();
        if (cached != null) {
          debugPrint('✅ Niveles desde caché: ${cached.length} items');
          return cached.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      }
    }

    // Verificar rate limiting
    final shouldThrottle = await _cacheService.checkRateLimit('memberships');
    if (shouldThrottle && !forceRefresh) {
      final cached = await _cacheService.getCachedMemberships();
      if (cached != null) {
        debugPrint('⚠️ Rate limit: usando caché');
        return cached.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    }

    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$wpBaseUrl/memberpressproduct'),
          headers: _defaultHeaders,
        ).timeout(slowTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final result = decoded.map((item) {
            final map = item as Map<String, dynamic>;
            return {
              'id': map['id'],
              'title': map['title']?['rendered'] ?? '',
              'slug': map['slug'] ?? '',
              'description': map['content']?['rendered'] ?? '',
              'excerpt': map['excerpt']?['rendered'] ?? '',
            };
          }).toList();
          
          // Guardar en caché
          await _cacheService.saveCachedMemberships(result);
          
          return result;
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo todos los niveles: $e');
      // Intentar usar caché como fallback
      final cached = await _cacheService.getCachedMemberships();
      if (cached != null) {
        return cached.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    }
  }

  // ============================================
  // ENDPOINTS DE PROGRAMAS (Tutor LMS)
  // ============================================

  /// Obtener programas Tutor LMS
  Future<List<Map<String, dynamic>>> getTutorCourses({bool forceRefresh = false}) async {
    // Verificar caché si no se fuerza refresh
    if (!forceRefresh) {
      final cached = await _cacheService.getCachedCourses();
      if (cached != null) {
        debugPrint('✅ Programas desde caché: ${cached.length} items');
        return cached.map((item) => Map<String, dynamic>.from(item)).toList();
      }
    }

    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/programas-tutor'),
          headers: _defaultHeaders,
        ).timeout(slowTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          final result = List<Map<String, dynamic>>.from(decoded);
          // Guardar en caché
          await _cacheService.saveCachedCourses(result);
          return result;
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo programas: $e');
      // Intentar usar caché como fallback
      final cached = await _cacheService.getCachedCourses();
      if (cached != null) {
        return cached.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      return [];
    }
  }

  /// Obtener detalles de un programa Tutor LMS
  Future<Map<String, dynamic>?> getTutorCourseDetails(int courseId) async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/detalles-programa-tutor?course_id=$courseId'),
          headers: _defaultHeaders,
        ).timeout(slowTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo detalles del programa: $e');
      return null;
    }
  }

  /// Verificar si el usuario está inscrito en un curso
  Future<bool> checkUserEnrollment(String email, int courseId, {bool forceRefresh = false}) async {
    // Verificar caché si no se fuerza refresh
    if (!forceRefresh) {
      final cached = await _cacheService.getCachedEnrollment(email, courseId);
      if (cached != null) {
        debugPrint('✅ Inscripción desde caché: $cached');
        return cached;
      }
    }

    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/tutor/enrollment?email=${Uri.encodeComponent(email)}&course_id=$courseId'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final isEnrolled = decoded is Map && (decoded['is_enrolled'] == true);
        
        // Guardar en caché
        await _cacheService.saveCachedEnrollment(email, courseId, isEnrolled);
        
        return isEnrolled;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error verificando inscripción: $e');
      // Intentar usar caché como fallback
      final cached = await _cacheService.getCachedEnrollment(email, courseId);
      return cached ?? false;
    }
  }

  // ============================================
  // ENDPOINTS DE SERVICIOS
  // ============================================

  /// Obtener sesiones ThetaFenix
  Future<List<Map<String, dynamic>>> getThetaFenixSessions() async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/theta-sessions'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is List ? List<Map<String, dynamic>>.from(decoded) : [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo sesiones Theta: $e');
      return [];
    }
  }

  /// Obtener contenido de sanación
  Future<Map<String, dynamic>?> getSanacionContent({String? slug}) async {
    try {
      final uri = slug != null
          ? Uri.parse('$baseUrl/sanacion?slug=${Uri.encodeComponent(slug)}')
          : Uri.parse('$baseUrl/sanacion');
      
      final response = await _retryWithBackoff(() async {
        return await http.get(
          uri,
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo contenido de sanación: $e');
      return null;
    }
  }

  /// Obtener contenido de tratamiento
  Future<List<Map<String, dynamic>>> getTratamientoContent() async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/tratamiento'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is List ? List<Map<String, dynamic>>.from(decoded) : [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo contenido de tratamiento: $e');
      return [];
    }
  }

  /// Obtener contenido de numerología
  Future<List<Map<String, dynamic>>> getNumerologiaContent() async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/numerologia'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is List ? List<Map<String, dynamic>>.from(decoded) : [];
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo contenido de numerología: $e');
      return [];
    }
  }

  // ============================================
  // ENDPOINTS DE VERIFICACIÓN
  // ============================================

  /// Verificar acceso a programa específico (adquirido en web externa)
  Future<bool> checkProgramPurchase(String email, String programType) async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$baseUrl/check-purchase?email=${Uri.encodeComponent(email)}&program_type=${Uri.encodeComponent(programType)}'),
          headers: _defaultHeaders,
        ).timeout(normalTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded is Map && (decoded['has_purchase'] == true);
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error verificando acceso a programa: $e');
      return false;
    }
  }
}

/// Tipo de contenido
enum ContentType { hipnosis, meditacion, otro }

/// Contenido del usuario (adquirido en web externa)
class UserContent {
  final List<ContentItem> purchases; // Nombre interno, no visible al usuario

  UserContent({required this.purchases});

  /// Todo el contenido
  List<ContentItem> get all => purchases;
  
  /// Solo hipnosis
  List<ContentItem> get hypnosis => 
      purchases.where((item) => item.type == ContentType.hipnosis).toList();
  
  /// Solo meditaciones
  List<ContentItem> get meditations => 
      purchases.where((item) => item.type == ContentType.meditacion).toList();
  
  /// Otros contenidos
  List<ContentItem> get other => 
      purchases.where((item) => item.type == ContentType.otro).toList();

  bool get isEmpty => purchases.isEmpty;
  bool get isNotEmpty => purchases.isNotEmpty;
}

/// Item de contenido (meditación, hipnosis, etc.)
class ContentItem {
  final int id;
  final int? woocommerceId;
  final String title;
  final String? description;
  final String? category;
  final String? image;
  final String? downloadUrl;

  ContentItem({
    required this.id,
    this.woocommerceId,
    required this.title,
    this.description,
    this.category,
    this.image,
    this.downloadUrl,
  });

  /// Detectar tipo por título o categoría
  ContentType get type {
    final lowerTitle = title.toLowerCase();
    final lowerCategory = (category ?? '').toLowerCase();
    
    if (lowerTitle.contains('meditación') || 
        lowerTitle.contains('meditacion') ||
        lowerCategory.contains('meditación') ||
        lowerCategory.contains('meditacion')) {
      return ContentType.meditacion;
    }
    
    if (lowerTitle.contains('hipnosis') || 
        lowerCategory.contains('hipnosis')) {
      return ContentType.hipnosis;
    }
    
    // Por defecto, asumir hipnosis si no tiene prefijo claro
    return ContentType.hipnosis;
  }

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    // Buscar URL de audio en múltiples campos posibles (como en FenixRn)
    String? downloadUrl;
    
    // 1. download_url (singular, snake_case)
    if (json['download_url'] != null && json['download_url'].toString().isNotEmpty) {
      downloadUrl = json['download_url'] as String?;
    }
    // 2. downloadUrl (camelCase)
    else if (json['downloadUrl'] != null && json['downloadUrl'].toString().isNotEmpty) {
      downloadUrl = json['downloadUrl'] as String?;
    }
    // 3. download_urls (plural, array - tomar el primero)
    else if (json['download_urls'] != null) {
      final urls = json['download_urls'];
      if (urls is List && urls.isNotEmpty) {
        downloadUrl = urls[0].toString();
      }
    }
    // 4. file (de WooCommerce)
    else if (json['file'] != null && json['file'].toString().isNotEmpty) {
      downloadUrl = json['file'] as String?;
    }
    // 5. audio_url
    else if (json['audio_url'] != null && json['audio_url'].toString().isNotEmpty) {
      downloadUrl = json['audio_url'] as String?;
    }
    // 6. media_url
    else if (json['media_url'] != null && json['media_url'].toString().isNotEmpty) {
      downloadUrl = json['media_url'] as String?;
    }
    
    return ContentItem(
      id: json['id'] as int? ?? 
          json['product_id'] as int? ?? 
          json['post_id'] as int? ?? 0,
      woocommerceId: json['woocommerce_id'] as int? ?? json['product_id'] as int?,
      title: json['title'] as String? ?? 
             json['post_title'] as String? ?? 
             json['name'] as String? ?? 
             'Sin título',
      description: json['description'] as String? ?? 
                   json['excerpt'] as String? ??
                   json['content'] as String? ??
                   json['post_content'] as String? ??
                   json['summary'] as String?,
      category: json['category'] as String? ?? 
                (json['categories'] is List && (json['categories'] as List).isNotEmpty
                    ? (json['categories'] as List)[0].toString()
                    : null),
      image: json['image'] as String? ?? 
             json['image_url'] as String? ?? 
             json['thumbnail'] as String?,
      downloadUrl: downloadUrl,
    );
  }
}
