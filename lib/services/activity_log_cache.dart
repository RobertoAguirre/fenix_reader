import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Caché local de actividad (título y hora) para mostrar en el modal del calendario.
const String _keyPrefix = 'fenix_activity_log_';

Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

/// Guardar un ítem al registrar actividad (se llama junto con el POST).
Future<void> addActivityItem({
  required String email,
  required DateTime occurredAt,
  required String contentType,
  required String title,
}) async {
  try {
    final dateStr = '${occurredAt.year}-${occurredAt.month.toString().padLeft(2, '0')}-${occurredAt.day.toString().padLeft(2, '0')}';
    final timeStr = '${occurredAt.hour.toString().padLeft(2, '0')}:${occurredAt.minute.toString().padLeft(2, '0')}';
    final key = '$_keyPrefix${email}_$dateStr';
    final prefs = await _prefs;
    final existing = prefs.getString(key);
    final list = existing != null ? List<Map<String, dynamic>>.from(jsonDecode(existing) as List) : <Map<String, dynamic>>[];
    list.add({'type': contentType, 'title': title, 'at': timeStr});
    await prefs.setString(key, jsonEncode(list));
  } catch (e) {
    debugPrint('❌ activity_log_cache add: $e');
  }
}

/// Obtener ítems de actividad de un día para el modal.
Future<List<Map<String, String>>> getActivityItems(String email, String dateStr) async {
  try {
    final key = '$_keyPrefix${email}_$dateStr';
    final prefs = await _prefs;
    final s = prefs.getString(key);
    if (s == null) return [];
    final list = jsonDecode(s) as List;
    return list.map((e) => {
      'type': (e as Map)['type'] as String? ?? '',
      'title': e['title'] as String? ?? '',
      'at': e['at'] as String? ?? '',
    }).toList();
  } catch (e) {
    debugPrint('❌ activity_log_cache get: $e');
    return [];
  }
}
