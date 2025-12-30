/// Modelo de lección
class Lesson {
  final int id;
  final String title;
  final String? videoUrl;
  final String? duration;
  final bool isLocked;
  final String? description;

  const Lesson({
    required this.id,
    required this.title,
    this.videoUrl,
    this.duration,
    this.isLocked = false,
    this.description,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      videoUrl: json['video_url'] as String? ?? json['videoUrl'] as String?,
      duration: json['duration'] as String?,
      isLocked: json['is_locked'] as bool? ?? json['isLocked'] as bool? ?? false,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'video_url': videoUrl,
      'duration': duration,
      'is_locked': isLocked,
      'description': description,
    };
  }
}

