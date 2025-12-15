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
      body: Column(
        children: [
          // Header marrón
          _buildHeader(),
          // Tabs
          FenixPillTabs(
            tabs: _tabs,
            selectedIndex: _selectedTab,
            onTap: (index) => setState(() => _selectedTab = index),
          ),
          const SizedBox(height: 8),
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
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.raizSagrada,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(0),
        ),
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
          const SizedBox(height: 12),
          Text(
            'Buenas tardes,',
            style: AppTypography.kaushanTitle(
              fontSize: 18,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        // Sección Fénix alquimista
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Fénix alquimista',
            style: AppTypography.kaushanTitle(
              fontSize: 22,
              color: AppColors.expansionAlquimica,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Recursos para tu camino de transformación',
            style: AppTypography.ralewayLight(fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        // Card destacado
        ContentFeatureCard(
          title: 'Mensajes del universo',
          subtitle: 'Descubre los mensajes que hay para ti detrás de los números, animales, símbolos y más',
          buttonText: 'Leer ahora',
          onTap: () {
            // TODO: Navegar al contenido
          },
        ),
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
    );
  }
}

