import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/fenix_logo.dart';
import '../providers/auth_provider.dart';

/// Pantalla de Perfil/Menú
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                const SizedBox(height: 30),
                // Saludo
                Text(
                  'Bienvenida a tu espacio fénix.',
                  style: AppTypography.kaushanTitle(
                    fontSize: 20,
                    color: AppColors.expansionAlquimica,
                  ),
                ),
                const SizedBox(height: 40),
                // Logo centrado
                Center(
                  child: Column(
                    children: [
                      const FenixLogo(
                        size: 160,
                        color: AppColors.raizSagrada,
                      ),
                      const SizedBox(height: 20),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final displayName = authProvider.user?.displayName ?? 'Usuario';
                          return Text(
                            displayName,
                            style: AppTypography.kaushanTitle(
                              fontSize: 22,
                              color: AppColors.raizSagrada,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                // Opciones del menú
                _MenuItem(
                  icon: Icons.vpn_key_outlined,
                  label: AppConstants.portals,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.library_books_outlined,
                  label: AppConstants.myLibrary,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.auto_awesome_outlined,
                  label: AppConstants.myAccount,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.description_outlined,
                  label: AppConstants.termsConditions,
                  onTap: () {},
                ),
                _MenuItem(
                  icon: Icons.mail_outline,
                  label: AppConstants.contactUs,
                  onTap: () {},
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
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.raizSagrada,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: AppTypography.ralewayRegular(
                fontSize: 16,
                color: AppColors.raizSagrada,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
