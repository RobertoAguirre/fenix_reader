/// Modelo de meditación
class Meditation {
  final int id;
  final String title;
  final String description;
  final String audioUrl;
  final String? thumbnailUrl;
  final Duration duration;
  final String category;
  final DateTime createdAt;

  const Meditation({
    required this.id,
    required this.title,
    required this.description,
    required this.audioUrl,
    this.thumbnailUrl,
    required this.duration,
    required this.category,
    required this.createdAt,
  });

  factory Meditation.fromJson(Map<String, dynamic> json) {
    return Meditation(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      audioUrl: json['audio_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String?,
      duration: Duration(seconds: json['duration'] as int),
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'audio_url': audioUrl,
      'thumbnail_url': thumbnailUrl,
      'duration': duration.inSeconds,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

