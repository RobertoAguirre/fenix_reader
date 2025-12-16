import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/fenix_tab_bar.dart';
import '../widgets/content_card.dart';

/// Pantalla de Portales/Inicio con tabs
class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  int _selectedTab = 0;
  final _tabs = [
    AppConstants.home,
    AppConstants.hypnosisFenix,
    AppConstants.meditationsFenix,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      body: Column(
        children: [
          // Header marrón
          _buildHeader(),
          // Contenido
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.raizSagrada,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 8),
          Text(
            'Buenas tardes,',
            style: AppTypography.kaushanTitle(
              fontSize: 20,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          // Tabs
          _buildTabs(),
          const SizedBox(height: 20),
          // Sección Fénix alquimista
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Fénix alquimista',
              style: AppTypography.kaushanTitle(
                fontSize: 24,
                color: AppColors.raizSagrada,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Recursos para tu camino de transformación',
              style: AppTypography.ralewayRegular(
                fontSize: 13,
                color: AppColors.raizSagrada.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Card destacado grande
          _buildFeatureCard(),
          const SizedBox(height: 24),
          // Lista de contenido
          ContentListItem(
            title: 'Hipnosis - Depresión',
            onTap: () {},
            onFavoriteTap: () {},
          ),
          ContentListItem(
            title: 'Hipnosis - Libre de Azúcar',
            onTap: () {},
            onFavoriteTap: () {},
          ),
          ContentListItem(
            title: 'Hipnosis - Tiroides',
            onTap: () {},
            onFavoriteTap: () {},
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = index == _selectedTab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white : AppColors.expansionAlquimica,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _tabs[index],
                  style: AppTypography.ralewayBold(
                    fontSize: 11,
                    color: isSelected ? AppColors.raizSagrada : AppColors.white,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFeatureCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.raizSagrada.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen placeholder turquesa
          Container(
            width: double.infinity,
            height: 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.ascenso,
                  Color(0xFF9DD5D5),
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'FÉNIX',
                    style: AppTypography.ralewayBold(
                      fontSize: 32,
                      color: AppColors.raizSagrada,
                    ),
                  ),
                  Text(
                    'Mensajes del universo',
                    style: AppTypography.kaushanTitle(
                      fontSize: 22,
                      color: AppColors.raizSagrada,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wendy Staufert',
                    style: AppTypography.kaushanTitle(
                      fontSize: 14,
                      color: AppColors.raizSagrada.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Contenido del card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mensajes del universo',
                  style: AppTypography.ralewayBold(
                    fontSize: 16,
                    color: AppColors.raizSagrada,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Descubre los mensajes que hay para ti detrás de los números, animales, símbolos y más',
                  style: AppTypography.ralewayRegular(
                    fontSize: 13,
                    color: AppColors.raizSagrada.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 12),
                // Botón Leer ahora
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ascenso,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            color: AppColors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Leer ahora',
                            style: AppTypography.ralewayBold(
                              fontSize: 12,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
