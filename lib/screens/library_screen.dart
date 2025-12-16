import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/constants.dart';

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
    {'title': 'Fortalecer Relación de Pareja', 'favorite': false},
    {'title': 'Hipnosis - Depresión', 'favorite': false},
    {'title': 'Hipnosis - Libre de Azúcar', 'favorite': false},
    {'title': 'Hipnosis - Tiroides', 'favorite': false},
    {'title': 'Fortalecer Relación de Pareja', 'favorite': false},
    {'title': 'Hipnosis - Depresión', 'favorite': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      body: Column(
        children: [
          // Header marrón
          _buildHeader(),
          // Tabs
          _buildTabs(),
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
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      color: AppColors.raizSagrada,
      child: Center(
        child: Text(
          AppConstants.library,
          style: AppTypography.kaushanTitle(
            fontSize: 28,
            color: AppColors.expansionAlquimica,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.ascenso, width: 1),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = index == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ascenso : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: AppTypography.ralewayBold(
                    fontSize: 12,
                    color: isSelected ? AppColors.white : AppColors.raizSagrada,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildList() {
    final displayItems = _selectedTab == 1
        ? _items.where((item) => item['favorite'] == true).toList()
        : _items;

    if (displayItems.isEmpty && _selectedTab == 1) {
      return Center(
        child: Text(
          'No tienes favoritas aún',
          style: AppTypography.ralewayRegular(
            fontSize: 14,
            color: AppColors.raizSagrada.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: displayItems.length,
      itemBuilder: (context, index) {
        final item = displayItems[index];
        return _LibraryListItem(
          title: item['title'] as String,
          isFavorite: item['favorite'] as bool,
          onTap: () {
            // TODO: Navegar al contenido
          },
          onFavoriteTap: () {
            setState(() {
              final originalIndex = _items.indexOf(item);
              _items[originalIndex]['favorite'] = !(item['favorite'] as bool);
            });
          },
        );
      },
    );
  }
}

/// Item de lista para biblioteca con corazón verde oliva cuadrado
class _LibraryListItem extends StatelessWidget {
  final String title;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const _LibraryListItem({
    required this.title,
    this.isFavorite = false,
    this.onTap,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.origen,
          border: Border(
            bottom: BorderSide(
              color: AppColors.raizSagrada.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.raizSagrada.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: AppColors.raizSagrada.withValues(alpha: 0.4),
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Título
            Expanded(
              child: Text(
                title,
                style: AppTypography.ralewayRegular(fontSize: 15),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Corazón verde oliva cuadrado redondeado
            GestureDetector(
              onTap: onFavoriteTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.expansionAlquimica.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: AppColors.white,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
