/// Modelo de nivel de acceso
/// NOTA: Este modelo representa niveles de acceso, no membresías de pago
class Membership {
  final int id;
  final String title;
  final String slug;
  final String? description;
  final String? excerpt;
  final String? image;
  final String? permalink;
  final MembershipType? type;

  const Membership({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    this.excerpt,
    this.image,
    this.permalink,
    this.type,
  });

  factory Membership.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String? ?? json['name'] as String? ?? '';
    final tier = json['tier'] as String?;
    final idVal = _parseInt(json['id']);
    return Membership(
      id: idVal != 0 ? idVal : _parseInt(json['product_id']),
      title: title,
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      excerpt: json['excerpt'] as String?,
      image: json['image'] as String?,
      permalink: json['permalink'] as String?,
      type: _typeFromTier(tier) ?? _parseType(title),
    );
  }

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  static MembershipType? _typeFromTier(String? tier) {
    if (tier == null || tier.isEmpty) return null;
    switch (tier.toLowerCase()) {
      case 'raiz':
      case 'raíz':
        return MembershipType.raiz;
      case 'conexion':
      case 'conexión':
        return MembershipType.conexion;
      case 'despertar':
        return MembershipType.despertar;
      case 'maestria':
      case 'maestría':
        return MembershipType.maestria;
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'slug': slug,
      'description': description,
      'excerpt': excerpt,
      'image': image,
      'permalink': permalink,
    };
  }

  static MembershipType? _parseType(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('raíz') || lowerTitle.contains('raiz')) {
      return MembershipType.raiz;
    }
    if (lowerTitle.contains('conexión') || lowerTitle.contains('conexion')) {
      return MembershipType.conexion;
    }
    if (lowerTitle.contains('despertar')) {
      return MembershipType.despertar;
    }
    if (lowerTitle.contains('maestría') || lowerTitle.contains('maestria')) {
      return MembershipType.maestria;
    }
    return null;
  }
}

/// Tipo de nivel de acceso
enum MembershipType {
  raiz,
  conexion,
  despertar,
  maestria,
}

