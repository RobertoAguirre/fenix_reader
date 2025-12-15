import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colores del Branding Kit Fénix
class AppColors {
  // Paleta principal
  static const Color raizSagrada = Color(0xFF635049);      // Marrón cálido
  static const Color origen = Color(0xFFFFF9F5);           // Crema suave
  static const Color ascenso = Color(0xFF86CECE);          // Turquesa
  static const Color expansionAlquimica = Color(0xFFB7B570); // Verde oliva

  // Colores de soporte
  static const Color white = Colors.white;
  static const Color textLight = Color(0xFF9E9E9E);
  static const Color error = Color(0xFFE57373);
}

/// Tipografía del Branding Kit Fénix
class AppTypography {
  // Kaushan Script - Títulos principales, frases canalizadas
  static TextStyle kaushanTitle({
    double fontSize = 28,
    Color color = AppColors.expansionAlquimica,
  }) {
    return GoogleFonts.kaushanScript(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.normal,
    );
  }

  // Raleway Bold - Títulos secundarios
  static TextStyle ralewayBold({
    double fontSize = 18,
    Color color = AppColors.raizSagrada,
  }) {
    return GoogleFonts.raleway(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w700,
    );
  }

  // Raleway Regular - Cuerpo de texto
  static TextStyle ralewayRegular({
    double fontSize = 14,
    Color color = AppColors.raizSagrada,
  }) {
    return GoogleFonts.raleway(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w400,
    );
  }

  // Raleway Light - Pie de página
  static TextStyle ralewayLight({
    double fontSize = 12,
    Color color = AppColors.raizSagrada,
  }) {
    return GoogleFonts.raleway(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w300,
    );
  }
}

/// Tema principal de Fénix
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.origen,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ascenso,
        secondary: AppColors.expansionAlquimica,
        surface: AppColors.origen,
        onPrimary: AppColors.white,
        onSecondary: AppColors.white,
        onSurface: AppColors.raizSagrada,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.raizSagrada,
        foregroundColor: AppColors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.kaushanScript(
          fontSize: 24,
          color: AppColors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ascenso,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          textStyle: GoogleFonts.raleway(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.ascenso, width: 2),
        ),
        hintStyle: GoogleFonts.raleway(
          color: AppColors.textLight,
          fontSize: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.origen,
        selectedItemColor: AppColors.ascenso,
        unselectedItemColor: AppColors.raizSagrada,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }
}
