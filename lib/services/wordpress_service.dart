import '../models/meditation.dart';
import '../models/video.dart';

/// Servicio para consumir WordPress REST API
/// TODO: Implementar llamadas a la API
class WordPressService {
  final String baseUrl;

  WordPressService({required this.baseUrl});

  /// Obtener lista de meditaciones
  Future<List<Meditation>> getMeditations() async {
    // TODO: Implementar GET /wp-json/...
    throw UnimplementedError();
  }

  /// Obtener meditación por ID
  Future<Meditation?> getMeditationById(int id) async {
    // TODO: Implementar GET /wp-json/.../id
    throw UnimplementedError();
  }

  /// Obtener lista de videos
  Future<List<Video>> getVideos() async {
    // TODO: Implementar GET /wp-json/...
    throw UnimplementedError();
  }

  /// Obtener video por ID
  Future<Video?> getVideoById(int id) async {
    // TODO: Implementar GET /wp-json/.../id
    throw UnimplementedError();
  }
}

