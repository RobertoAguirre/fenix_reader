import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Logo del Fénix - Usa imagen desde assets
class FenixLogo extends StatelessWidget {
  final double size;
  final Color? color; // Opcional para filtro de color si se necesita

  const FenixLogo({
    super.key,
    this.size = 150,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logotriangulo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback si la imagen no existe
        return Icon(
          Icons.auto_awesome,
          size: size,
          color: color ?? AppColors.expansionAlquimica,
        );
      },
    );
  }
}

/// Ícono del Fénix simple (para usar en lugares pequeños)
class FenixIcon extends StatelessWidget {
  final double size;
  final Color color;

  const FenixIcon({
    super.key,
    this.size = 40,
    this.color = AppColors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.auto_awesome,
      size: size,
      color: color,
    );
  }
}

