import 'package:flutter/foundation.dart';
import '../services/wordpress_service.dart';

/// Provider de contenido del usuario
class ContentProvider extends ChangeNotifier {
  final WordPressService _wpService = WordPressService();
  
  UserContent? _content;
  bool _isLoading = false;
  String? _error;

  UserContent? get content => _content;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Todo el contenido comprado
  List<ContentItem> get all => _content?.all ?? [];
  
  /// Solo hipnosis compradas
  List<ContentItem> get hypnosis => _content?.hypnosis ?? [];
  
  /// Solo meditaciones compradas
  List<ContentItem> get meditations => _content?.meditations ?? [];

  bool get hasContent => _content?.isNotEmpty ?? false;

  /// Cargar contenido del usuario
  Future<void> loadUserContent(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _content = await _wpService.getUserContent(email);
    } catch (e) {
      _error = 'Error al cargar contenido';
      debugPrint('❌ Error cargando contenido: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Limpiar contenido (logout)
  void clear() {
    _content = null;
    _error = null;
    notifyListeners();
  }
}
