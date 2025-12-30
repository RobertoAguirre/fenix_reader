import 'package:flutter/foundation.dart';
import '../services/wordpress_service.dart';
import '../models/membership.dart';

/// Provider de niveles de acceso
/// NOTA: Maneja niveles de acceso del usuario, no membresías de pago
class MembershipProvider extends ChangeNotifier {
  final WordPressService _wpService = WordPressService();

  List<Membership> _activeMemberships = [];
  List<Membership> _allMemberships = [];
  bool _isLoading = false;
  bool _isLoadingAll = false;
  String? _error;

  List<Membership> get activeMemberships => _activeMemberships;
  List<Membership> get allMemberships => _allMemberships;
  bool get isLoading => _isLoading;
  bool get isLoadingAll => _isLoadingAll;
  String? get error => _error;

  bool get hasActiveMemberships => _activeMemberships.isNotEmpty;
  bool get hasAllMemberships => _allMemberships.isNotEmpty;

  /// Cargar niveles de acceso activos del usuario
  Future<void> loadUserMemberships(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _wpService.getUserMemberships(email);
      _activeMemberships = data.map((item) => Membership.fromJson(item)).toList();
    } catch (e) {
      _error = 'Error al cargar niveles de acceso';
      debugPrint('❌ Error cargando niveles de acceso: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar todos los niveles de acceso disponibles
  Future<void> loadAllMemberships({bool forceRefresh = false}) async {
    _isLoadingAll = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _wpService.getAllMemberships(forceRefresh: forceRefresh);
      _allMemberships = data.map((item) => Membership.fromJson(item)).toList();
    } catch (e) {
      _error = 'Error al cargar niveles disponibles';
      debugPrint('❌ Error cargando niveles disponibles: $e');
    } finally {
      _isLoadingAll = false;
      notifyListeners();
    }
  }

  /// Obtener niveles agrupados por tipo
  Map<MembershipType, List<Membership>> get membershipsByType {
    final Map<MembershipType, List<Membership>> grouped = {};
    for (final membership in _allMemberships) {
      if (membership.type != null) {
        grouped.putIfAbsent(membership.type!, () => []).add(membership);
      }
    }
    return grouped;
  }

  /// Limpiar datos (logout)
  void clear() {
    _activeMemberships = [];
    _allMemberships = [];
    _error = null;
    notifyListeners();
  }
}

