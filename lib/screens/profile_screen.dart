import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/fenix_logo.dart';

/// Pantalla de Perfil
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          // Contenido
          Expanded(
            child: _buildContent(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 30,
      ),
      decoration: const BoxDecoration(
        color: AppColors.raizSagrada,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () => Scaffold.of(context).openDrawer(),
                  child: const Icon(
                    Icons.menu,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          // Avatar placeholder
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.ascenso.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.ascenso, width: 2),
            ),
            child: const Icon(
              Icons.person,
              size: 40,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Mi Perfil',
            style: AppTypography.kaushanTitle(
              fontSize: 24,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _ProfileOption(
          icon: Icons.person_outline,
          title: 'Datos personales',
          onTap: () {},
        ),
        _ProfileOption(
          icon: Icons.lock_outline,
          title: 'Cambiar contraseña',
          onTap: () {},
        ),
        _ProfileOption(
          icon: Icons.notifications_none,
          title: 'Notificaciones',
          onTap: () {},
        ),
        _ProfileOption(
          icon: Icons.help_outline,
          title: 'Ayuda',
          onTap: () {},
        ),
        const SizedBox(height: 30),
        // Logo y firma
        Center(
          child: Column(
            children: [
              const FenixLogo(size: 60),
              const SizedBox(height: 8),
              Text(
                'Wendy Staufert',
                style: AppTypography.kaushanTitle(
                  fontSize: 18,
                  color: AppColors.expansionAlquimica,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        // Cerrar sesión
        Center(
          child: TextButton(
            onPressed: () {
              // TODO: Implementar logout
            },
            child: Text(
              'Cerrar sesión',
              style: AppTypography.ralewayRegular(
                fontSize: 14,
                color: AppColors.raizSagrada.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.raizSagrada.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.raizSagrada),
        title: Text(
          title,
          style: AppTypography.ralewayRegular(fontSize: 15),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.raizSagrada,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

