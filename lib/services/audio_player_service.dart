import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'audio_cache_service.dart';

/// Servicio para reproducir audio
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final AudioCacheService _cacheService = AudioCacheService();

  // Streams públicos
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // Getters
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  PlayerState get playerState => _player.playerState;
  bool get isPlaying => _player.playing;
  bool get isLoading => _player.processingState == ProcessingState.loading;

  /// Reproducir audio desde URL (usa caché local si está disponible)
  Future<void> play(String url) async {
    try {
      // Intentar obtener archivo en caché
      final cachedPath = await _cacheService.getCachedFilePath(url);
      
      if (cachedPath != null) {
        // Reproducir desde archivo local
        debugPrint('✅ Reproduciendo desde caché local: $cachedPath');
        await _player.setFilePath(cachedPath);
      } else {
        // Descargar y cachear mientras reproduce
        debugPrint('📥 Descargando y cacheando audio...');
        try {
          final localPath = await _cacheService.downloadAndCache(url);
          await _player.setFilePath(localPath);
          debugPrint('✅ Audio descargado y guardado en caché');
        } catch (e) {
          // Si falla la descarga, intentar streaming directo
          debugPrint('⚠️ Falló descarga, usando streaming: $e');
          await _player.setUrl(url);
        }
      }
      
      await _player.play();
    } catch (e) {
      debugPrint('❌ Error reproduciendo audio: $e');
      rethrow;
    }
  }

  /// Pausar reproducción
  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (e) {
      debugPrint('❌ Error pausando audio: $e');
    }
  }

  /// Reanudar reproducción (sin recargar)
  Future<void> resume() async {
    try {
      await _player.play();
    } catch (e) {
      debugPrint('❌ Error reanudando audio: $e');
      rethrow;
    }
  }

  /// Detener reproducción
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('❌ Error deteniendo audio: $e');
    }
  }

  /// Avanzar posición
  Future<void> seek(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('❌ Error buscando posición: $e');
    }
  }

  /// Avanzar 10 segundos
  Future<void> seekForward() async {
    try {
      final currentPosition = _player.position;
      final newPosition = currentPosition + const Duration(seconds: 10);
      final maxDuration = _player.duration ?? Duration.zero;
      await _player.seek(newPosition > maxDuration ? maxDuration : newPosition);
    } catch (e) {
      debugPrint('❌ Error avanzando: $e');
    }
  }

  /// Retroceder 10 segundos
  Future<void> seekBackward() async {
    try {
      final currentPosition = _player.position;
      final newPosition = currentPosition - const Duration(seconds: 10);
      await _player.seek(newPosition.isNegative ? Duration.zero : newPosition);
    } catch (e) {
      debugPrint('❌ Error retrocediendo: $e');
    }
  }

  /// Limpiar recursos
  Future<void> dispose() async {
    await _player.dispose();
  }
}

