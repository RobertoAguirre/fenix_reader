import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../widgets/fenix_tab_bar.dart';
import '../widgets/content_card.dart';

/// Pantalla de Biblioteca
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTab = 0;
  final _tabs = [AppConstants.myContent, AppConstants.favorites];

  // Datos de ejemplo
  final _items = [
    'Fortalecer Relación de Pareja',
    'Hipnosis - Depresión',
    'Hipnosis - Libre de Azúcar',
    'Hipnosis - Tiroides',
    'Fortalecer Relación de Pareja',
    'Hipnosis - Depresión',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      body: Column(
        children: [
          // Header
          _buildHeader(),
          // Tabs
          FenixTabBar(
            tabs: _tabs,
            selectedIndex: _selectedTab,
            onTap: (index) => setState(() => _selectedTab = index),
          ),
          const SizedBox(height: 8),
          // Lista de contenido
          Expanded(
            child: _buildList(),
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
      color: AppColors.ascenso,
      child: Center(
        child: Text(
          AppConstants.library,
          style: AppTypography.kaushanTitle(
            fontSize: 28,
            color: AppColors.raizSagrada,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_selectedTab == 1) {
      // Favoritos - mostrar solo algunos
      return ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: 2,
        itemBuilder: (context, index) {
          return ContentListItem(
            title: _items[index],
            isFavorite: true,
            onTap: () {
              // TODO: Navegar al contenido
            },
            onFavoriteTap: () {
              // TODO: Toggle favorito
            },
          );
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _items.length,
      itemBuilder: (context, index) {
        return ContentListItem(
          title: _items[index],
          isFavorite: index < 2,
          onTap: () {
            // TODO: Navegar al contenido
          },
          onFavoriteTap: () {
            // TODO: Toggle favorito
          },
        );
      },
    );
  }
}

