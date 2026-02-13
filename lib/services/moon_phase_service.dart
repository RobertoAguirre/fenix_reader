import 'dart:math' as math;

/// Cálculo local de la fase lunar (sin API).
/// Referencia: luna nueva 2000-01-06 18:14 UTC; mes sinódico ≈ 29.530588853 días.
class MoonPhaseService {
  /// Referencia: nueva luna conocida (UTC).
  static final DateTime _refNewMoon = DateTime.utc(2000, 1, 6, 18, 14);

  /// Mes sinódico en días (lunación media).
  static const double _synodicMonth = 29.530588853;

  /// Fase lunar para la fecha y hora dadas (usa hora local del dispositivo).
  static MoonPhaseData getPhase(DateTime d) {
    final utc = d.toUtc();
    final daysSince = utc.difference(_refNewMoon).inMilliseconds / (24 * 60 * 60 * 1000);
    double cycle = (daysSince / _synodicMonth) % 1.0;
    if (cycle < 0) cycle += 1.0;

    // Iluminación: fracción del disco iluminado (0 = nueva, 1 = llena).
    final illumination = (1 - math.cos(cycle * 2 * math.pi)) / 2;

    // Índice 0-7: nueva, creciente, cuarto crec., gibosa crec., llena, gibosa meng., cuarto meng., menguante.
    final index = (cycle * 8).floor() % 8;

    return MoonPhaseData(
      index: index,
      illumination: illumination,
      cycle: cycle,
    );
  }
}

class MoonPhaseData {
  final int index;
  final double illumination;
  final double cycle;

  const MoonPhaseData({
    required this.index,
    required this.illumination,
    required this.cycle,
  });
}
