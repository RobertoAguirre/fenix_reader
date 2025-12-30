import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../config/theme.dart';
import '../services/audio_player_service.dart';
import '../utils/audio_helper.dart';

/// Función helper para mostrar el reproductor de audio
Future<void> showAudioPlayer({
  required BuildContext context,
  required String audioUrl,
  required String title,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AudioPlayerContent(
      audioUrl: audioUrl,
      title: title,
    ),
  );
}

/// Contenido del reproductor de audio
class _AudioPlayerContent extends StatefulWidget {
  final String audioUrl;
  final String title;

  const _AudioPlayerContent({
    required this.audioUrl,
    required this.title,
  });

  @override
  State<_AudioPlayerContent> createState() => _AudioPlayerContentState();
}

class _AudioPlayerContentState extends State<_AudioPlayerContent> {
  final AudioPlayerService _audioService = AudioPlayerService();
  bool _isLoading = true;
  String? _error;
  Duration _position = Duration.zero;
  Duration? _duration;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
    _loadAudio();
  }

  void _setupAudioListeners() {
    _audioService.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioService.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading;
        });
      }
    });
  }

  Future<void> _loadAudio() async {
    if (widget.audioUrl.isEmpty) {
      setState(() {
        _error = 'URL de audio no válida';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Normalizar URL (convertir Google Drive a enlace directo si es necesario)
      final normalizedUrl = AudioHelper.normalizeAudioUrl(widget.audioUrl);
      await _audioService.play(normalizedUrl);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar el audio';
        _isLoading = false;
      });
      debugPrint('❌ Error cargando audio: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _audioService.pause();
    } else {
      final normalizedUrl = AudioHelper.normalizeAudioUrl(widget.audioUrl);
      await _audioService.play(normalizedUrl);
    }
  }

  Future<void> _seekForward() async {
    await _audioService.seekForward();
  }

  Future<void> _seekBackward() async {
    await _audioService.seekBackward();
  }

  Future<void> _onSeek(Duration position) async {
    await _audioService.seek(position);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.origen,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTypography.ralewayBold(fontSize: 18),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppColors.raizSagrada,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: AppTypography.ralewayRegular(
                          fontSize: 12,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Loading
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.ascenso),
              ),

            // Controles
            if (!_isLoading && _error == null) ...[
              // Barra de progreso
              Slider(
                value: _duration != null && _duration!.inMilliseconds > 0
                    ? _position.inMilliseconds.toDouble()
                    : 0.0,
                min: 0.0,
                max: _duration?.inMilliseconds.toDouble() ?? 1.0,
                activeColor: AppColors.ascenso,
                inactiveColor: AppColors.raizSagrada.withOpacity(0.2),
                onChanged: (value) {
                  _onSeek(Duration(milliseconds: value.toInt()));
                },
              ),

              // Tiempo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: AppTypography.ralewayRegular(
                        fontSize: 12,
                        color: AppColors.raizSagrada.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: AppTypography.ralewayRegular(
                        fontSize: 12,
                        color: AppColors.raizSagrada.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botones de control
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Retroceder 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    iconSize: 32,
                    color: AppColors.raizSagrada,
                    onPressed: _seekBackward,
                  ),
                  const SizedBox(width: 16),

                  // Play/Pause
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.ascenso,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                      iconSize: 40,
                      color: AppColors.white,
                      onPressed: _togglePlayPause,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Avanzar 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    iconSize: 32,
                    color: AppColors.raizSagrada,
                    onPressed: _seekForward,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
