import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio para consumir WordPress REST API
class WordPressService {
  static const String baseUrl = 'https://wendystaufert.com/wp-json/fenix/v1';

  /// Obtener contenido comprado por el usuario
  Future<UserContent> getUserContent(String email) async {
    debugPrint('📦 Obteniendo contenido comprado para: $email');

    final purchases = await _getUserPurchases(email);

    final content = UserContent(purchases: purchases);

    _logContent(content);
    return content;
  }

  /// Obtener compras del usuario
  Future<List<ContentItem>> _getUserPurchases(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-purchases?email=$email'),
      );

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
        
        debugPrint('✅ Contenido comprado: ${data.length} items');
        return data.map((item) => ContentItem.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        debugPrint('⚠️ Error obteniendo compras: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error en user-purchases: $e');
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
}

/// Tipo de contenido
enum ContentType { hipnosis, meditacion, otro }

/// Contenido del usuario (solo comprado)
class UserContent {
  final List<ContentItem> purchases;

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
    return ContentItem(
      id: json['id'] as int? ?? 0,
      woocommerceId: json['woocommerce_id'] as int?,
      title: json['title'] as String? ?? 'Sin título',
      description: json['description'] as String?,
      category: json['category'] as String?,
      image: json['image'] as String?,
      downloadUrl: json['download_url'] as String?,
    );
  }
}
