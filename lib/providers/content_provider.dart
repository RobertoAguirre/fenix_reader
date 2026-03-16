import 'package:flutter/foundation.dart';
import '../services/wordpress_service.dart';
import '../services/cache_service.dart';

/// Provider de contenido del usuario
class ContentProvider extends ChangeNotifier {
  final WordPressService _wpService = WordPressService();
  
  UserContent? _content;
  List<ContentItem> _publicMeditaciones = [];
  List<ContentItem> _publicHipnosis = [];
  List<Map<String, dynamic>> _programs = [];
  bool _isLoading = false;
  bool _isLoadingPublic = false;
  bool _isLoadingPrograms = false;
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

  /// Programas comprados del usuario
  List<Map<String, dynamic>> get programs => _programs;
  
  bool get isLoadingPrograms => _isLoadingPrograms;

  /// Meditaciones públicas
  List<ContentItem> get publicMeditaciones => _publicMeditaciones;

  /// Hipnosis públicas
  List<ContentItem> get publicHipnosis => _publicHipnosis;

  bool get hasContent => _content?.isNotEmpty ?? false;
  bool get hasPublicContent => _publicMeditaciones.isNotEmpty || _publicHipnosis.isNotEmpty;

  /// Sincronizar compras/membresía con el servidor (sin caché). Tras comprar en web o nueva membresía.
  Future<void> syncPurchasesFromServer(String email) async {
    await CacheService().clearPurchasesCache(email);
    await loadUserContent(email, forceRefresh: true);
    await loadUserPrograms(email, forceRefresh: true);
  }

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

  /// Cargar programas comprados del usuario
  Future<void> loadUserPrograms(String email, {bool forceRefresh = false}) async {
    _isLoadingPrograms = true;
    notifyListeners();

    try {
      _programs = await _wpService.getUserPrograms(email, forceRefresh: forceRefresh);
    } catch (e) {
      _error = 'Error al cargar programas';
      debugPrint('❌ Error cargando programas: $e');
    } finally {
      _isLoadingPrograms = false;
      notifyListeners();
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
    _programs = [];
    _error = null;
    notifyListeners();
  }
}
