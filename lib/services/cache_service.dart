import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio para gestionar caché de respuestas API
class CacheService {
  // Claves de caché
  static const String _purchasesCachePrefix = 'fenix_purchases_cache_';
  static const String _membershipsCacheKey = 'fenix_memberships_cache';
  static const String _enrollmentCachePrefix = 'fenix_enrollment_cache_';
  static const String _coursesCacheKey = 'fenix_courses_cache';
  static const String _rateLimitPrefix = 'fenix_rate_limit_';

  // Duración de caché (en minutos)
  static const int purchasesCacheDuration = 10; // 10 minutos
  static const int membershipsCacheDuration = 60; // 60 minutos
  static const int enrollmentCacheDuration = 120; // 2 horas
  static const int coursesCacheDuration = 60; // 1 hora

  /// Obtener instancia de SharedPreferences
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ============================================
  // CACHÉ DE CONTENIDO DEL USUARIO
  // ============================================

  /// Obtener contenido del usuario del caché
  Future<List<dynamic>?> getCachedPurchases(String email) async {
    try {
      final prefs = await _prefs;
      final cacheKey = '$_purchasesCachePrefix$email';
      final cached = prefs.getString(cacheKey);
      
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = decoded['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Validar expiración (10 minutos)
        if (now - timestamp < purchasesCacheDuration * 60 * 1000) {
          return decoded['data'] as List<dynamic>?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo caché de contenido: $e');
      return null;
    }
  }

  /// Guardar contenido del usuario en caché
  Future<void> saveCachedPurchases(String email, List<dynamic> data) async {
    try {
      final prefs = await _prefs;
      final cacheKey = '$_purchasesCachePrefix$email';
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('❌ Error guardando caché de contenido: $e');
    }
  }

  /// Verificar si el caché de contenido del usuario es válido
  Future<bool> isPurchasesCacheValid(String email, {int? maxAgeMinutes}) async {
    try {
      final prefs = await _prefs;
      final cacheKey = '$_purchasesCachePrefix$email';
      final cached = prefs.getString(cacheKey);
      
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = decoded['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        final maxAge = (maxAgeMinutes ?? purchasesCacheDuration) * 60 * 1000;
        
        return (now - timestamp) < maxAge;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Limpiar caché de contenido del usuario
  Future<void> clearPurchasesCache(String email) async {
    try {
      final prefs = await _prefs;
      final cacheKey = '$_purchasesCachePrefix$email';
      await prefs.remove(cacheKey);
    } catch (e) {
      debugPrint('❌ Error limpiando caché de contenido: $e');
    }
  }

  // ============================================
  // CACHÉ DE NIVELES DE ACCESO
  // ============================================

  /// Obtener niveles de acceso del caché
  Future<List<dynamic>?> getCachedMemberships() async {
    try {
      final prefs = await _prefs;
      final cached = prefs.getString(_membershipsCacheKey);
      
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = decoded['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Validar expiración (60 minutos)
        if (now - timestamp < membershipsCacheDuration * 60 * 1000) {
          return decoded['data'] as List<dynamic>?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo caché de niveles: $e');
      return null;
    }
  }

  /// Guardar niveles de acceso en caché
  Future<void> saveCachedMemberships(List<dynamic> data) async {
    try {
      final prefs = await _prefs;
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_membershipsCacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('❌ Error guardando caché de niveles: $e');
    }
  }

  /// Verificar si el caché de niveles es válido
  Future<bool> isMembershipsCacheValid({int? maxAgeMinutes}) async {
    try {
      final prefs = await _prefs;
      final cached = prefs.getString(_membershipsCacheKey);
      
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = decoded['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        final maxAge = (maxAgeMinutes ?? membershipsCacheDuration) * 60 * 1000;
        
        return (now - timestamp) < maxAge;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Limpiar caché de niveles de acceso
  Future<void> clearMembershipsCache() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_membershipsCacheKey);
    } catch (e) {
      debugPrint('❌ Error limpiando caché de niveles: $e');
    }
  }

  // ============================================
  // CACHÉ DE INSCRIPCIONES
  // ============================================

  /// Obtener inscripción del caché
  Future<bool?> getCachedEnrollment(String email, int courseId) async {
    try {
      final prefs = await _prefs;
      final cacheKey = '$_enrollmentCachePrefix${email}_$courseId';
      final cached = prefs.getString(cacheKey);
      
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = decoded['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Validar expiración (2 horas)
        if (now - timestamp < enrollmentCacheDuration * 60 * 1000) {
          return decoded['data'] as bool?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo caché de inscripción: $e');
      return null;
    }
  }

  /// Guardar inscripción en caché
  Future<void> saveCachedEnrollment(String email, int courseId, bool isEnrolled) async {
    try {
      final prefs = await _prefs;
      final cacheKey = '$_enrollmentCachePrefix${email}_$courseId';
      final cacheData = {
        'data': isEnrolled,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('❌ Error guardando caché de inscripción: $e');
    }
  }

  /// Limpiar caché de inscripción
  Future<void> clearEnrollmentCache(String email) async {
    try {
      final prefs = await _prefs;
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith('$_enrollmentCachePrefix$email')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      debugPrint('❌ Error limpiando caché de inscripción: $e');
    }
  }

  // ============================================
  // CACHÉ DE CURSOS
  // ============================================

  /// Obtener cursos del caché
  Future<List<dynamic>?> getCachedCourses() async {
    try {
      final prefs = await _prefs;
      final cached = prefs.getString(_coursesCacheKey);
      
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final timestamp = decoded['timestamp'] as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        // Validar expiración (1 hora)
        if (now - timestamp < coursesCacheDuration * 60 * 1000) {
          return decoded['data'] as List<dynamic>?;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo caché de cursos: $e');
      return null;
    }
  }

  /// Guardar cursos en caché
  Future<void> saveCachedCourses(List<dynamic> data) async {
    try {
      final prefs = await _prefs;
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_coursesCacheKey, jsonEncode(cacheData));
    } catch (e) {
      debugPrint('❌ Error guardando caché de cursos: $e');
    }
  }

  /// Limpiar caché de cursos
  Future<void> clearCoursesCache() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_coursesCacheKey);
    } catch (e) {
      debugPrint('❌ Error limpiando caché de cursos: $e');
    }
  }

  // ============================================
  // RATE LIMITING
  // ============================================

  /// Verificar rate limiting
  Future<bool> checkRateLimit(String endpoint) async {
    try {
      final prefs = await _prefs;
      final rateLimitKey = '$_rateLimitPrefix$endpoint';
      final cached = prefs.getString(rateLimitKey);
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (cached != null) {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        final count = decoded['count'] as int;
        final lastReset = decoded['lastReset'] as int;
        final timeSinceReset = now - lastReset;
        
        // Reset cada 5 minutos
        if (timeSinceReset > 5 * 60 * 1000) {
          await prefs.setString(rateLimitKey, jsonEncode({
            'count': 1,
            'lastReset': now,
          }));
          return false; // No hay rate limit
        }
        
        // Máximo 10 peticiones por 5 minutos por endpoint
        if (count >= 10) {
          debugPrint('🚫 Rate limit alcanzado para $endpoint: $count peticiones en 5 minutos');
          return true; // Hay rate limit
        }
        
        // Incrementar contador
        await prefs.setString(rateLimitKey, jsonEncode({
          'count': count + 1,
          'lastReset': lastReset,
        }));
        return false; // No hay rate limit
      } else {
        // Primera petición
        await prefs.setString(rateLimitKey, jsonEncode({
          'count': 1,
          'lastReset': now,
        }));
        return false; // No hay rate limit
      }
    } catch (e) {
      debugPrint('❌ Error verificando rate limit: $e');
      return false; // En caso de error, permitir petición
    }
  }
}

