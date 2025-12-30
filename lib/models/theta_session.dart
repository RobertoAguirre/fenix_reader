/// Modelo de sesión ThetaFenix
class ThetaSession {
  final int id;
  final String title;
  final String? description;
  final DateTime? date;
  final String? link;
  final String? image;

  const ThetaSession({
    required this.id,
    required this.title,
    this.description,
    this.date,
    this.link,
    this.image,
  });

  factory ThetaSession.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json['date'] != null) {
      try {
        parsedDate = DateTime.parse(json['date'] as String);
      } catch (e) {
        parsedDate = null;
      }
    }

    return ThetaSession(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      date: parsedDate,
      link: json['link'] as String?,
      image: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date?.toIso8601String(),
      'link': link,
      'image': image,
    };
  }
}

