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

  /// Obtener programas comprados del usuario
  Future<List<Map<String, dynamic>>> getUserPrograms(String email, {bool forceRefresh = false}) async {
    try {
      debugPrint('📚 Obteniendo programas comprados del usuario: $email');
      
      // Obtener todos los programas disponibles
      final allPrograms = await getTutorCourses(forceRefresh: forceRefresh);
      
      if (allPrograms.isEmpty) {
        debugPrint('⚠️ No hay programas disponibles');
        return [];
      }
      
      debugPrint('📚 Programas disponibles: ${allPrograms.length}');
      
      // Verificar cuáles tiene comprados el usuario
      final purchasedPrograms = <Map<String, dynamic>>[];
      
      for (final program in allPrograms) {
        final courseId = program['ID'] as int? ?? program['id'] as int?;
        if (courseId == null) continue;
        
        final isEnrolled = await checkUserEnrollment(email, courseId, forceRefresh: forceRefresh);
        
        if (isEnrolled) {
          purchasedPrograms.add(program);
          debugPrint('✅ Usuario tiene acceso a: ${program['post_title'] ?? program['title']}');
          
          // TEMPORAL: Obtener detalles del primer programa para extraer link de Vimeo
          if (purchasedPrograms.length == 1) {
            try {
              final details = await getTutorCourseDetails(courseId);
              if (details != null) {
                debugPrint('🔍 Analizando detalles del programa para encontrar video de Vimeo...');
                
                // Buscar vimeo_embed_code en topics y lessons
                final topics = details['topics'] as List<dynamic>? ?? [];
                debugPrint('📋 Topics encontrados: ${topics.length}');
                
                for (final topic in topics) {
                  final topicMap = topic as Map<String, dynamic>;
                  final lessons = topicMap['lessons'];
                  
                  if (lessons != null) {
                    List<dynamic> lessonsList = [];
                    if (lessons is Map && lessons['data'] != null) {
                      lessonsList = lessons['data'] as List<dynamic>? ?? [];
                    } else if (lessons is List) {
                      lessonsList = lessons;
                    }
                    
                    debugPrint('📚 Lessons en topic "${topicMap['post_title']}": ${lessonsList.length}');
                    
                    for (final lesson in lessonsList) {
                      final lessonMap = lesson as Map<String, dynamic>;
                      final vimeoCode = lessonMap['vimeo_embed_code'] as String? ?? 
                                       lessonMap['embed_code'] as String?;
                      
                      if (vimeoCode != null && vimeoCode.isNotEmpty) {
                        debugPrint('');
                        debugPrint('═══════════════════════════════════════════');
                        debugPrint('🎥 LINK DE VIMEO ENCONTRADO:');
                        debugPrint('═══════════════════════════════════════════');
                        debugPrint('Título del programa: ${program['post_title'] ?? program['title']}');
                        debugPrint('Topic: ${topicMap['post_title']}');
                        debugPrint('Lesson: ${lessonMap['post_title']}');
                        debugPrint('Vimeo Embed Code: $vimeoCode');
                        debugPrint('═══════════════════════════════════════════');
                        debugPrint('');
                        
                        // Extraer ID de Vimeo si es posible
                        final vimeoIdMatch = RegExp(r'vimeo\.com/(\d+)').firstMatch(vimeoCode);
                        final playerMatch = RegExp(r'player\.vimeo\.com/video/(\d+)').firstMatch(vimeoCode);
                        final idMatch = vimeoIdMatch ?? playerMatch;
                        
                        if (idMatch != null) {
                          final videoId = idMatch.group(1);
                          debugPrint('🎬 ID de Vimeo extraído: $videoId');
                          debugPrint('🔗 URL directa: https://vimeo.com/$videoId');
                          debugPrint('🔗 URL player: https://player.vimeo.com/video/$videoId');
                        }
                        debugPrint('');
                        break; // Solo mostrar el primero encontrado
                      }
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('⚠️ Error obteniendo detalles para debug: $e');
            }
          }
        }
      }
      
      debugPrint('✅ Programas comprados del usuario: ${purchasedPrograms.length}');
      return purchasedPrograms;
    } catch (e) {
      debugPrint('❌ Error obteniendo programas del usuario: $e');
      return [];
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

  /// Obtener sesiones de THETAFENIX
  Future<Map<String, dynamic>> getThetaFenixSessions() async {
    try {
      final response = await _retryWithBackoff(() async {
        return await http.get(
          Uri.parse('$wpBaseUrl/pages?search=thetahealing'),
          headers: _defaultHeaders,
        ).timeout(slowTimeout);
      });

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final pages = decoded is List ? List<Map<String, dynamic>>.from(decoded) : [];
        
        // Buscar la página de ThetaFénix Grupal
        final thetaFenixPage = pages.firstWhere(
          (page) {
            final title = page['title']?['rendered'] as String? ?? '';
            final slug = page['slug'] as String? ?? '';
            return title.toLowerCase().contains('thetafénix grupal') ||
                   title.toLowerCase().contains('thetafenix grupal') ||
                   slug.toLowerCase().contains('thetahealing');
          },
          orElse: () => <String, dynamic>{},
        );

        if (thetaFenixPage.isEmpty) {
          debugPrint('⚠️ Página de ThetaFénix no encontrada');
          return {
            'pageInfo': null,
            'sessions': <Map<String, dynamic>>[],
          };
        }

        // Parsear sesiones del HTML
        final content = thetaFenixPage['content']?['rendered'] as String? ?? '';
        final sessions = _parseSessionsFromHTML(content);

        return {
          'pageInfo': {
            'title': thetaFenixPage['title']?['rendered'] as String? ?? '',
            'description': thetaFenixPage['excerpt']?['rendered'] as String? ?? '',
          },
          'sessions': sessions,
        };
      }
      return {
        'pageInfo': null,
        'sessions': <Map<String, dynamic>>[],
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo sesiones de THETAFENIX: $e');
      return {
        'pageInfo': null,
        'sessions': <Map<String, dynamic>>[],
      };
    }
  }

  /// Parsear sesiones del HTML
  List<Map<String, dynamic>> _parseSessionsFromHTML(String htmlContent) {
    final sessions = <Map<String, dynamic>>[];
    
    // Regex para encontrar fechas y enlaces (solo para extraer fechas, no usamos los enlaces)
    final sessionRegex = RegExp(
      r'<h3[^>]*class="[^"]*elementor-heading-title[^"]*"[^>]*>([^<]+)</h3>',
      multiLine: true,
      dotAll: true,
    );
    
    final matches = sessionRegex.allMatches(htmlContent);
    
    for (final match in matches) {
      final dateText = match.group(1)?.trim() ?? '';
      
      // Parsear la fecha
      final dateMatch = RegExp(r'([A-Za-záéíóúñÁÉÍÓÚÑ]+)\s+(\d+)\s+([A-Za-záéíóúñÁÉÍÓÚÑ]+)').firstMatch(dateText);
      if (dateMatch != null) {
        final dayName = dateMatch.group(1) ?? '';
        final day = int.tryParse(dateMatch.group(2) ?? '') ?? 0;
        final month = dateMatch.group(3) ?? '';
        final year = 2025; // Año actual
        
        sessions.add({
          'id': 'session-${sessions.length + 1}',
          'date': '$day $month $year',
          'dayName': dayName,
          'day': day,
          'month': month,
          'year': year,
          'time': '8:30 PM CDMX',
          'duration': '1.5 hrs',
          'modality': 'Online por Zoom',
        });
      }
    }
    
    // Ordenar sesiones por fecha
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    sessions.sort((a, b) {
      final aMonthIndex = months.indexOf(a['month'] as String);
      final bMonthIndex = months.indexOf(b['month'] as String);
      
      if (aMonthIndex != bMonthIndex) {
        return aMonthIndex.compareTo(bMonthIndex);
      }
      return (a['day'] as int).compareTo(b['day'] as int);
    });
    
    return sessions;
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

/// Servicio para obtener URLs directas de videos de Vimeo
class VimeoService {
  static const String vimeoApiBase = 'https://api.vimeo.com';
  static const String _accessToken = '95e64bd6af030d1994fbccac73e5b11f';
  
  /// Obtener token de acceso de Vimeo
  Future<String> getVimeoAccessToken() async {
    return _accessToken;
  }

  /// Listar todos los videos de Vimeo del usuario
  Future<List<Map<String, dynamic>>> listVimeoVideos() async {
    try {
      final accessToken = await getVimeoAccessToken();
      List<Map<String, dynamic>> allVideos = [];
      int page = 1;
      bool hasMore = true;
      
      // Obtener todas las páginas (hasta 500 videos)
      while (hasMore && page <= 10) {
        final response = await http.get(
          Uri.parse('$vimeoApiBase/me/videos?fields=uri,name,duration,link&per_page=100&page=$page'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ).timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            final data = decoded['data'] as List<dynamic>?;
            if (data != null && data.isNotEmpty) {
              final videos = data.map((video) {
                final uri = video['uri'] as String? ?? '';
                // Extraer ID del URI (formato: /videos/123456)
                final videoId = uri.replaceAll('/videos/', '');
                
                return {
                  'id': videoId,
                  'title': video['name'] as String? ?? 'Sin título',
                  'duration': video['duration'] as int? ?? 0,
                  'link': video['link'] as String? ?? '',
                  'uri': uri,
                };
              }).toList();
              
              allVideos.addAll(videos);
              
              // Verificar si hay más páginas
              final paging = decoded['paging'] as Map<String, dynamic>?;
              final next = paging?['next'] as String?;
              hasMore = next != null;
              page++;
            } else {
              hasMore = false;
            }
          }
        } else {
          debugPrint('❌ Error listando videos: ${response.statusCode} - ${response.body}');
          hasMore = false;
        }
      }
      
      return allVideos;
    } catch (e) {
      debugPrint('❌ Error listando videos de Vimeo: $e');
      return [];
    }
  }

  /// Buscar videos específicos por nombre (para videos introductorios)
  Future<Map<String, dynamic>?> findVideoByName(String searchName) async {
    try {
      final videos = await listVimeoVideos();
      final lowerSearch = searchName.toLowerCase();
      
      for (var video in videos) {
        final title = (video['title'] as String? ?? '').toLowerCase();
        if (title.contains(lowerSearch)) {
          return video;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error buscando video por nombre: $e');
      return null;
    }
  }

  /// Obtener URL directa de video de Vimeo
  Future<String?> getVimeoVideoUrl(String videoId) async {
    try {
      final accessToken = await getVimeoAccessToken();
      
      final response = await http.get(
        Uri.parse('$vimeoApiBase/videos/$videoId?fields=play'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final play = decoded['play'] as Map<String, dynamic>?;
          if (play != null) {
            // Intentar obtener URL progresiva (MP4)
            final progressive = play['progressive'] as List<dynamic>?;
            if (progressive != null && progressive.isNotEmpty) {
              // Obtener la mejor calidad disponible
              final bestQuality = progressive.last as Map<String, dynamic>;
              final url = bestQuality['url'] as String?;
              if (url != null) {
                return url;
              }
            }
            
            // Si no hay progresivo, intentar HLS
            final hls = play['hls'] as Map<String, dynamic>?;
            if (hls != null) {
              final link = hls['link'] as String?;
              if (link != null) {
                return link;
              }
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo URL de video de Vimeo: $e');
      return null;
    }
  }
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
    
    // Debug: mostrar todos los campos relacionados con video/url para tappings
    final title = (json['title'] as String? ?? json['post_title'] as String? ?? '').toLowerCase();
    if (title.contains('tapping')) {
      debugPrint('🔍 TAPPING detectado: ${json['title'] ?? json['post_title']}');
      debugPrint('   Buscando campos de video...');
      ['download_url', 'downloadUrl', 'download_urls', 'file', 'audio_url', 'media_url', 'video_url', 
       'vimeo_url', 'vimeo_id', 'video_id', 'url', 'link'].forEach((field) {
        if (json[field] != null) {
          debugPrint('   ✅ $field: ${json[field]}');
        }
      });
    }
    
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
    // 7. video_url (para videos de Vimeo en tappings)
    else if (json['video_url'] != null && json['video_url'].toString().isNotEmpty) {
      downloadUrl = json['video_url'] as String?;
    }
    // 8. vimeo_url
    else if (json['vimeo_url'] != null && json['vimeo_url'].toString().isNotEmpty) {
      downloadUrl = json['vimeo_url'] as String?;
    }
    // 9. vimeo_id (convertir ID a URL)
    else if (json['vimeo_id'] != null && json['vimeo_id'].toString().isNotEmpty) {
      final vimeoId = json['vimeo_id'].toString();
      downloadUrl = 'https://vimeo.com/$vimeoId';
    }
    // 10. video_id (convertir ID a URL)
    else if (json['video_id'] != null && json['video_id'].toString().isNotEmpty) {
      final videoId = json['video_id'].toString();
      downloadUrl = 'https://vimeo.com/$videoId';
    }
    
    // Convertir URL de "manage" a URL de visualización si es necesario
    if (downloadUrl != null && downloadUrl.contains('vimeo.com/manage/videos/')) {
      final manageMatch = RegExp(r'vimeo\.com/manage/videos/(\d+)').firstMatch(downloadUrl);
      if (manageMatch != null) {
        final videoId = manageMatch.group(1)!;
        downloadUrl = 'https://vimeo.com/$videoId';
        debugPrint('🔄 URL convertida de manage a visualización: $downloadUrl');
      }
    }
    
    if (title.contains('tapping') && downloadUrl != null) {
      debugPrint('   ✅ downloadUrl asignado: $downloadUrl');
    } else if (title.contains('tapping') && downloadUrl == null) {
      debugPrint('   ❌ downloadUrl NO encontrado para tapping');
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
