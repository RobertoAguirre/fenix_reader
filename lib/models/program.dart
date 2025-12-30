import 'lesson.dart';

/// Modelo de programa Tutor LMS
class Program {
  final int id;
  final String title;
  final String? description;
  final String? image;
  final List<Topic> topics;
  final bool isEnrolled;

  const Program({
    required this.id,
    required this.title,
    this.description,
    this.image,
    this.topics = const [],
    this.isEnrolled = false,
  });

  factory Program.fromJson(Map<String, dynamic> json) {
    final topicsData = json['topics'] as List<dynamic>? ?? [];
    return Program(
      id: json['id'] as int? ?? json['course_id'] as int? ?? 0,
      title: json['title'] as String? ?? json['post_title'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      topics: topicsData
          .map((t) => Topic.fromJson(t as Map<String, dynamic>))
          .toList(),
      isEnrolled: json['is_enrolled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image': image,
      'topics': topics.map((topic) => topic.toJson()).toList(),
      'is_enrolled': isEnrolled,
    };
  }
}

/// Modelo de tema dentro de un programa
class Topic {
  final int id;
  final String title;
  final List<Lesson> lessons;

  const Topic({
    required this.id,
    required this.title,
    this.lessons = const [],
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    final lessonsData = json['lessons'] as List<dynamic>? ?? [];
    return Topic(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      lessons: lessonsData
          .map((l) => Lesson.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'lessons': lessons.map((lesson) => lesson.toJson()).toList(),
    };
  }
}

