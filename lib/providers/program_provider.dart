import 'package:flutter/foundation.dart';
import '../services/wordpress_service.dart';
import '../models/program.dart';

/// Provider de programas Tutor LMS
class ProgramProvider extends ChangeNotifier {
  final WordPressService _wpService = WordPressService();

  List<Program> _programs = [];
  Program? _selectedProgram;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _error;

  List<Program> get programs => _programs;
  Program? get selectedProgram => _selectedProgram;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get error => _error;

  bool get hasPrograms => _programs.isNotEmpty;

  /// Cargar lista de programas
  Future<void> loadPrograms({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _wpService.getTutorCourses(forceRefresh: forceRefresh);
      _programs = data.map((item) => Program.fromJson(item)).toList();
    } catch (e) {
      _error = 'Error al cargar programas';
      debugPrint('❌ Error cargando programas: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar detalles de un programa específico
  Future<void> loadProgramDetails(int courseId) async {
    _isLoadingDetails = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _wpService.getTutorCourseDetails(courseId);
      if (data != null) {
        _selectedProgram = Program.fromJson(data);
      }
    } catch (e) {
      _error = 'Error al cargar detalles del programa';
      debugPrint('❌ Error cargando detalles: $e');
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  /// Verificar inscripción del usuario en un curso
  Future<bool> checkEnrollment(String email, int courseId, {bool forceRefresh = false}) async {
    try {
      return await _wpService.checkUserEnrollment(email, courseId, forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('❌ Error verificando inscripción: $e');
      return false;
    }
  }

  /// Limpiar datos (logout)
  void clear() {
    _programs = [];
    _selectedProgram = null;
    _error = null;
    notifyListeners();
  }
}

