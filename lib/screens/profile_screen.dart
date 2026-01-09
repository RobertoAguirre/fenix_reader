import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/fenix_logo.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../providers/membership_provider.dart';
import '../providers/program_provider.dart';
import '../services/cache_service.dart';
import '../main.dart';
import 'terms_screen.dart';

/// Pantalla de Perfil/Menú
class ProfileScreen extends StatelessWidget {
  final Function(int)? onNavigateToIndex;
  
  const ProfileScreen({super.key, this.onNavigateToIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Saludo con nombre completo
                Center(
                  child: Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final displayName = authProvider.user?.displayName ?? 'Usuario';
                      final capitalizedName = displayName.isNotEmpty
                          ? displayName[0].toUpperCase() + displayName.substring(1)
                          : displayName;
                      return Column(
                        children: [
                          Text(
                            '$capitalizedName,',
                            textAlign: TextAlign.center,
                            style: AppTypography.kaushanTitle(
                              fontSize: 24,
                              color: AppColors.expansionAlquimica,
                            ),
                          ),
                          Text(
                            'Bienvenida a tu espacio fénix.',
                            textAlign: TextAlign.center,
                            style: AppTypography.kaushanTitle(
                              fontSize: 24,
                              color: AppColors.expansionAlquimica,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 1),
                // Logo centrado
                Center(
                  child: Column(
                    children: [
                      Opacity(
                        opacity: 0.7,
                        child: const FenixLogo(
                          size: 360,
                          color: AppColors.raizSagrada,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 1),
                // Opciones del menú
                _MenuItem(
                  imagePath: 'assets/images/ankh.png',
                  label: AppConstants.portals,
                  onTap: () {
                    if (onNavigateToIndex != null) {
                      onNavigateToIndex!(0);
                    }
                  },
                ),
                _MenuItem(
                  imagePath: 'assets/images/biblioteca.png',
                  label: AppConstants.myLibrary,
                  onTap: () {
                    if (onNavigateToIndex != null) {
                      onNavigateToIndex!(1);
                    }
                  },
                ),
                _MenuItem(
                  icon: Icons.article,
                  label: AppConstants.termsConditions,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsScreen(),
                      ),
                    );
                  },
                ),
                _MenuItem(
                  icon: Icons.email,
                  label: AppConstants.contactUs,
                  onTap: () {
                    // TODO: Abrir contacto
                  },
                ),
                _MenuItem(
                  icon: Icons.exit_to_app,
                  label: 'Cerrar sesión',
                  onTap: () async {
                    // Obtener email del usuario antes de hacer logout
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final userEmail = authProvider.user?.email;
                    
                    // Limpiar todos los providers
                    final contentProvider = Provider.of<ContentProvider>(context, listen: false);
                    final membershipProvider = Provider.of<MembershipProvider>(context, listen: false);
                    final programProvider = Provider.of<ProgramProvider>(context, listen: false);
                    
                    // Limpiar contenido y caché
                    contentProvider.clear();
                    membershipProvider.clear();
                    programProvider.clear();
                    
                    // Limpiar caché si tenemos el email
                    if (userEmail != null) {
                      final cacheService = CacheService();
                      await cacheService.clearPurchasesCache(userEmail);
                    }
                    
                    // Logout de autenticación (esto limpia el storage)
                    await authProvider.logout();
                    
                    // Navegar al AppNavigator para que muestre el LoginScreen con el callback
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const AppNavigator(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    this.icon,
    this.imagePath,
    required this.label,
    required this.onTap,
  }) : assert(icon != null || imagePath != null, 'Debe proporcionar icon o imagePath');

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 300,
            child: Row(
              children: [
                if (imagePath != null)
                  Image.asset(
                    imagePath!,
                    width: 24,
                    height: 24,
                    color: AppColors.raizSagrada,
                  )
                else if (icon != null)
                  Icon(
                    icon,
                    color: AppColors.raizSagrada,
                    size: 24,
                  ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    color: AppColors.raizSagrada,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
