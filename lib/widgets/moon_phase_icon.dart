import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../services/moon_phase_service.dart';

/// Icono de la fase lunar actual (calculado localmente, fecha y hora exactas).
class MoonPhaseIcon extends StatelessWidget {
  const MoonPhaseIcon({super.key});

  static const _phases = ['🌑', '🌒', '🌓', '🌔', '🌕', '🌖', '🌗', '🌘'];

  @override
  Widget build(BuildContext context) {
    final data = MoonPhaseService.getPhase(DateTime.now());
    final emoji = _phases[data.index];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.origen.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.raizSagrada.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 22),
      ),
    );
  }
}
