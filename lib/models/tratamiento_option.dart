/// Modelo de opción de tratamiento
class TratamientoOption {
  final int id;
  final String title;
  final String? description;
  final String? link;
  final String? image;
  final String? waitingListLink;

  const TratamientoOption({
    required this.id,
    required this.title,
    this.description,
    this.link,
    this.image,
    this.waitingListLink,
  });

  factory TratamientoOption.fromJson(Map<String, dynamic> json) {
    return TratamientoOption(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      link: json['link'] as String?,
      image: json['image'] as String?,
      waitingListLink: json['waiting_list_link'] as String? ?? json['waitingListLink'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'link': link,
      'image': image,
      'waiting_list_link': waitingListLink,
    };
  }
}

