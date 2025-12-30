import 'package:flutter/foundation.dart';
import '../services/wordpress_service.dart';

/// Provider de contenido del usuario
class ContentProvider extends ChangeNotifier {
  final WordPressService _wpService = WordPressService();
  
  UserContent? _content;
  List<ContentItem> _publicMeditaciones = [];
  List<ContentItem> _publicHipnosis = [];
  bool _isLoading = false;
  bool _isLoadingPublic = false;
  String? _error;

  UserContent? get content => _content;
  bool get isLoading => _isLoading;
  bool get isLoadingPublic => _isLoadingPublic;
  String? get error => _error;
  
  /// Todo el contenido del usuario
  List<ContentItem> get all => _content?.all ?? [];
  
  /// Solo hipnosis del usuario
  List<ContentItem> get hypnosis => _content?.hypnosis ?? [];
  
  /// Solo meditaciones del usuario
  List<ContentItem> get meditations => _content?.meditations ?? [];

  /// Meditaciones públicas
  List<ContentItem> get publicMeditaciones => _publicMeditaciones;

  /// Hipnosis públicas
  List<ContentItem> get publicHipnosis => _publicHipnosis;

  bool get hasContent => _content?.isNotEmpty ?? false;
  bool get hasPublicContent => _publicMeditaciones.isNotEmpty || _publicHipnosis.isNotEmpty;

  /// Cargar contenido del usuario
  Future<void> loadUserContent(String email, {bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _content = await _wpService.getUserContent(email, forceRefresh: forceRefresh);
    } catch (e) {
      _error = 'Error al cargar contenido';
      debugPrint('❌ Error cargando contenido: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar meditaciones del usuario
  Future<void> loadUserMeditaciones(String email) async {
    try {
      final meditaciones = await _wpService.getUserMeditaciones(email);
      // Actualizar contenido si existe
      if (_content != null) {
        // Combinar con contenido existente
        final allItems = [..._content!.all, ...meditaciones];
        _content = UserContent(purchases: allItems);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error cargando meditaciones: $e');
    }
  }

  /// Cargar hipnosis del usuario
  Future<void> loadUserHipnosis(String email) async {
    try {
      final hipnosis = await _wpService.getUserHipnosis(email);
      // Actualizar contenido si existe
      if (_content != null) {
        // Combinar con contenido existente
        final allItems = [..._content!.all, ...hipnosis];
        _content = UserContent(purchases: allItems);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error cargando hipnosis: $e');
    }
  }

  /// Cargar contenido público
  Future<void> loadPublicContent() async {
    _isLoadingPublic = true;
    notifyListeners();

    try {
      _publicMeditaciones = await _wpService.getPublicMeditaciones();
      _publicHipnosis = await _wpService.getPublicHipnosis();
    } catch (e) {
      debugPrint('❌ Error cargando contenido público: $e');
    } finally {
      _isLoadingPublic = false;
      notifyListeners();
    }
  }

  /// Limpiar contenido (logout)
  void clear() {
    _content = null;
    _publicMeditaciones = [];
    _publicHipnosis = [];
    _error = null;
    notifyListeners();
  }
}
