/// Modelo de contenido de sanación
class SanacionContent {
  final String? title;
  final String? content;
  final String? slug;
  final List<SanacionCard> cards;

  const SanacionContent({
    this.title,
    this.content,
    this.slug,
    this.cards = const [],
  });

  factory SanacionContent.fromJson(Map<String, dynamic> json) {
    final cardsData = json['cards'] as List<dynamic>? ?? [];
    return SanacionContent(
      title: json['title'] as String?,
      content: json['content'] as String?,
      slug: json['slug'] as String?,
      cards: cardsData.map((c) => SanacionCard.fromJson(c as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'slug': slug,
      'cards': cards.map((c) => c.toJson()).toList(),
    };
  }
}

/// Modelo de card de sanación
class SanacionCard {
  final String title;
  final String? description;
  final String? link;
  final String? image;

  const SanacionCard({
    required this.title,
    this.description,
    this.link,
    this.image,
  });

  factory SanacionCard.fromJson(Map<String, dynamic> json) {
    return SanacionCard(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      link: json['link'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'link': link,
      'image': image,
    };
  }
}

