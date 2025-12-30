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
    return Membership(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String?,
      excerpt: json['excerpt'] as String?,
      image: json['image'] as String?,
      permalink: json['permalink'] as String?,
      type: _parseType(json['title'] as String? ?? ''),
    );
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

