import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'video_player_modal.dart';

/// Helper para reproducir videos (detecta Vimeo y abre externamente, otros videos nativamente)
class VideoHelper {
  /// Detecta si una URL es de Vimeo
  static bool isVimeoUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.contains('vimeo.com') || url.contains('player.vimeo.com');
  }

  /// Convierte URL de Vimeo a formato de visualización
  static String getVimeoWatchUrl(String vimeoUrl) {
    // Extraer ID de Vimeo
    final vimeoIdMatch = RegExp(r'vimeo\.com/(\d+)').firstMatch(vimeoUrl);
    if (vimeoIdMatch != null) {
      final videoId = vimeoIdMatch.group(1);
      return 'https://vimeo.com/$videoId';
    }
    
    // Si ya es una URL de player, convertir a watch
    final playerMatch = RegExp(r'player\.vimeo\.com/video/(\d+)').firstMatch(vimeoUrl);
    if (playerMatch != null) {
      final videoId = playerMatch.group(1);
      return 'https://vimeo.com/$videoId';
    }
    
    return vimeoUrl;
  }

  /// Reproduce un video (abre Vimeo externamente, otros videos nativamente)
  static Future<void> playVideo({
    required BuildContext context,
    required String videoUrl,
    required String title,
  }) async {
    if (videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('URL de video no válida'),
        ),
      );
      return;
    }

    // Si es Vimeo, abrir en navegador/app externa
    if (isVimeoUrl(videoUrl)) {
      final watchUrl = getVimeoWatchUrl(videoUrl);
      final uri = Uri.parse(watchUrl);
      
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir el video'),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('❌ Error abriendo Vimeo: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al abrir el video'),
            ),
          );
        }
      }
    } else {
      // Para videos directos (MP4, etc.), usar reproductor nativo
      await showVideoPlayer(
        context: context,
        videoUrl: videoUrl,
        title: title,
      );
    }
  }
}

