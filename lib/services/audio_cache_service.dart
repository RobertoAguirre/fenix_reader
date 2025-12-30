import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de caché de audio
/// Descarga y guarda archivos de audio en directorio privado de la app
/// Los archivos NO son compartibles (directorio privado)
class AudioCacheService {
  static const String _trackingKey = 'audio_file_tracking';
  static const int _cacheExpirationDays = 8;

  /// Obtener ruta del directorio de caché (privado, no compartible)
  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/audio_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// Generar nombre de archivo único basado en URL
  String _getFileName(String url) {
    // Usar hash de la URL como nombre de archivo
    final hash = url.hashCode.abs();
    final extension = _getFileExtension(url);
    return 'audio_$hash$extension';
  }

  /// Obtener extensión del archivo desde URL
  String _getFileExtension(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.mp3')) return '.mp3';
    if (lowerUrl.contains('.wav')) return '.wav';
    if (lowerUrl.contains('.m4a')) return '.m4a';
    if (lowerUrl.contains('.aac')) return '.aac';
    return '.mp3'; // Por defecto
  }

  /// Obtener ruta local del archivo si existe en caché
  Future<String?> getCachedFilePath(String url) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileName(url);
      final filePath = '${cacheDir.path}/$fileName';
      final file = File(filePath);

      if (await file.exists()) {
        // Verificar que el archivo no esté vacío
        final stat = await file.stat();
        if (stat.size > 0) {
          // Registrar uso del archivo
          await _trackFileUsage(filePath);
          return filePath;
        } else {
          // Eliminar archivo corrupto
          await file.delete();
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error obteniendo archivo en caché: $e');
      return null;
    }
  }

  /// Descargar y guardar audio en caché
  Future<String> downloadAndCache(String url, {Function(int, int)? onProgress}) async {
    try {
      final cacheDir = await _getCacheDirectory();
      final fileName = _getFileName(url);
      final filePath = '${cacheDir.path}/$fileName';
      final file = File(filePath);

      // Si ya existe, retornar ruta
      if (await file.exists()) {
        final stat = await file.stat();
        if (stat.size > 0) {
          await _trackFileUsage(filePath);
          return filePath;
        }
      }

      // Descargar archivo
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'Flutter/FenixReader'},
      );

      if (response.statusCode == 200) {
        // Guardar archivo
        await file.writeAsBytes(response.bodyBytes);
        await _trackFileUsage(filePath);
        return filePath;
      } else {
        throw Exception('Error descargando audio: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error descargando y guardando audio: $e');
      rethrow;
    }
  }

  /// Registrar uso de archivo para tracking
  Future<void> _trackFileUsage(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final trackingJson = prefs.getString(_trackingKey) ?? '{}';
      final tracking = Map<String, dynamic>.from(jsonDecode(trackingJson));
      
      tracking[filePath] = {
        'lastUsed': DateTime.now().millisecondsSinceEpoch,
        'downloadedAt': tracking[filePath]?['downloadedAt'] ?? DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_trackingKey, jsonEncode(tracking));
    } catch (e) {
      debugPrint('❌ Error registrando uso de archivo: $e');
    }
  }

  /// Limpiar archivos no usados en los últimos 8 días
  Future<void> cleanupOldFiles() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) return;

      final prefs = await SharedPreferences.getInstance();
      final trackingJson = prefs.getString(_trackingKey) ?? '{}';
      final tracking = Map<String, dynamic>.from(jsonDecode(trackingJson));
      
      final now = DateTime.now().millisecondsSinceEpoch;
      final expirationMs = _cacheExpirationDays * 24 * 60 * 60 * 1000;
      
      int filesDeleted = 0;
      
      for (final entry in tracking.entries) {
        final filePath = entry.key;
        final fileInfo = entry.value as Map<String, dynamic>;
        final lastUsed = fileInfo['lastUsed'] as int? ?? now;
        
        if (now - lastUsed > expirationMs) {
          try {
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
              filesDeleted++;
            }
            tracking.remove(filePath);
          } catch (e) {
            debugPrint('❌ Error eliminando archivo: $e');
          }
        }
      }

      // Guardar tracking actualizado
      await prefs.setString(_trackingKey, jsonEncode(tracking));
      
      if (filesDeleted > 0) {
        debugPrint('✅ Limpieza de caché: $filesDeleted archivos eliminados');
      }
    } catch (e) {
      debugPrint('❌ Error en limpieza de caché: $e');
    }
  }

  /// Obtener información del caché
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final cacheDir = await _getCacheDirectory();
      if (!await cacheDir.exists()) {
        return {'fileCount': 0, 'totalSize': 0};
      }

      final files = cacheDir.listSync();
      final audioFiles = files.where((file) {
        if (file is! File) return false;
        final name = file.path.toLowerCase();
        return name.endsWith('.mp3') || 
               name.endsWith('.wav') || 
               name.endsWith('.m4a') || 
               name.endsWith('.aac');
      }).toList();

      int totalSize = 0;
      for (final file in audioFiles) {
        if (file is File) {
          final stat = await file.stat();
          totalSize += stat.size;
        }
      }

      return {
        'fileCount': audioFiles.length,
        'totalSize': totalSize,
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo info de caché: $e');
      return {'fileCount': 0, 'totalSize': 0};
    }
  }
}

