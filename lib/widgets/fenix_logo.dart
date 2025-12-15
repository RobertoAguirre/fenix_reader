import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Logo del Fénix con triángulo
class FenixLogo extends StatelessWidget {
  final double size;
  final Color color;

  const FenixLogo({
    super.key,
    this.size = 120,
    this.color = AppColors.expansionAlquimica,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _FenixLogoPainter(color: color),
      ),
    );
  }
}

class _FenixLogoPainter extends CustomPainter {
  final Color color;

  _FenixLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    
    // Triángulo exterior
    final trianglePath = Path();
    trianglePath.moveTo(size.width / 2, size.height * 0.1);
    trianglePath.lineTo(size.width * 0.15, size.height * 0.85);
    trianglePath.lineTo(size.width * 0.85, size.height * 0.85);
    trianglePath.close();
    canvas.drawPath(trianglePath, paint);

    // Círculo central
    canvas.drawCircle(center, size.width * 0.2, paint);

    // Fénix simplificado (alas)
    final birdPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Cuerpo central
    final bodyPath = Path();
    bodyPath.moveTo(center.dx, center.dy - 15);
    bodyPath.lineTo(center.dx - 8, center.dy + 10);
    bodyPath.lineTo(center.dx + 8, center.dy + 10);
    bodyPath.close();
    canvas.drawPath(bodyPath, birdPaint);

    // Ala izquierda
    final leftWing = Path();
    leftWing.moveTo(center.dx - 5, center.dy);
    leftWing.quadraticBezierTo(
      center.dx - 25, center.dy - 15,
      center.dx - 20, center.dy + 5,
    );
    canvas.drawPath(leftWing, paint..style = PaintingStyle.stroke);

    // Ala derecha
    final rightWing = Path();
    rightWing.moveTo(center.dx + 5, center.dy);
    rightWing.quadraticBezierTo(
      center.dx + 25, center.dy - 15,
      center.dx + 20, center.dy + 5,
    );
    canvas.drawPath(rightWing, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

