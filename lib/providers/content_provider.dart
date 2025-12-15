import 'package:flutter/foundation.dart';
import '../models/meditation.dart';
import '../models/video.dart';

/// Provider de contenido (meditaciones y videos)
/// TODO: Implementar lógica cuando wordpress_service esté listo
class ContentProvider extends ChangeNotifier {
  List<Meditation> _meditations = [];
  List<Video> _videos = [];
  bool _isLoading = false;

  List<Meditation> get meditations => _meditations;
  List<Video> get videos => _videos;
  bool get isLoading => _isLoading;

  Future<void> loadMeditations() async {
    // TODO: Implementar
  }

  Future<void> loadVideos() async {
    // TODO: Implementar
  }
}

