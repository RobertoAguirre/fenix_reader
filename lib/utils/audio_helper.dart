/// Helper para manejar URLs de audio y Google Drive
class AudioHelper {
  /// Detecta si una URL es de audio por extensión
  static bool isAudioUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('.mp3') ||
        lowerUrl.contains('.wav') ||
        lowerUrl.contains('.m4a') ||
        lowerUrl.contains('.aac') ||
        lowerUrl.contains('drive.google.com');
  }

  /// Convierte URL de Google Drive a enlace directo de descarga
  static String getDirectGoogleDriveLink(String? url) {
    if (url == null || url.isEmpty) return url ?? '';

    // Si no es Google Drive, retornar URL original
    if (!url.contains('drive.google.com') && !url.contains('docs.google.com')) {
      return url;
    }

    String? fileId;

    // Formato: https://drive.google.com/file/d/FILE_ID/view
    if (url.contains('drive.google.com') && url.contains('/file/d/')) {
      final match = RegExp(r'/file/d/([a-zA-Z0-9_-]+)').firstMatch(url);
      if (match != null && match.groupCount > 0) {
        fileId = match.group(1);
      }
    }
    // Formato: https://drive.google.com/open?id=FILE_ID
    else if (url.contains('drive.google.com') && url.contains('id=')) {
      final match = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(url);
      if (match != null && match.groupCount > 0) {
        fileId = match.group(1);
      }
    }
    // Formato: https://docs.google.com/uc?export=download&id=FILE_ID
    else if (url.contains('docs.google.com') && url.contains('id=')) {
      final match = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(url);
      if (match != null && match.groupCount > 0) {
        fileId = match.group(1);
      }
    }

    if (fileId != null) {
      // Usar el formato de descarga directa de Google Drive
      return 'https://drive.google.com/uc?export=download&id=$fileId';
    }

    return url;
  }

  /// Normaliza URL de audio (convierte Google Drive si es necesario)
  static String normalizeAudioUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    return getDirectGoogleDriveLink(url);
  }
}

