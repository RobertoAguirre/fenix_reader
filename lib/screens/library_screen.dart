import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/content_provider.dart';
import '../services/activity_log_cache.dart';
import '../services/wordpress_service.dart';
import '../services/favorites_service.dart';
import '../widgets/audio_player_modal.dart';
import '../utils/audio_helper.dart';

/// Pantalla de Biblioteca
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int _selectedTab = 0;
  final _tabs = [AppConstants.myContent, AppConstants.favorites];
  
  final FavoritesService _favoritesService = FavoritesService();
  final Set<int> _favoriteIds = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
    _searchController.addListener(() {
      setState(() {}); // Actualizar cuando cambia el texto de búsqueda
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavorites();
    setState(() {
      _favoriteIds.clear();
      _favoriteIds.addAll(favorites);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      body: Column(
        children: [
          _buildHeader(),
          _buildTabs(),
          const SizedBox(height: 8),
          _buildSearchBar(),
          const SizedBox(height: 8),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.raizSagrada.withValues(alpha: 0.2),
          ),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar...',
            hintStyle: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: AppColors.raizSagrada.withValues(alpha: 0.5),
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: AppColors.raizSagrada.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          style: AppTypography.ralewayRegular(
            fontSize: 14,
            color: AppColors.raizSagrada,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.ascenso),
          );
        }

        final allItems = provider.all;
        
        // Filtrar según pestaña
        var displayItems = _selectedTab == 1
            ? allItems.where((item) => _favoriteIds.contains(item.id)).toList()
            : allItems;
        
        // Filtrar por búsqueda
        final searchQuery = _searchController.text.toLowerCase().trim();
        if (searchQuery.isNotEmpty) {
          displayItems = displayItems.where((item) {
            final title = item.title.toLowerCase();
            final description = (item.description ?? '').toLowerCase();
            final category = (item.category ?? '').toLowerCase();
            return title.contains(searchQuery) ||
                   description.contains(searchQuery) ||
                   category.contains(searchQuery);
          }).toList();
        }

        if (displayItems.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: displayItems.length,
          itemBuilder: (context, index) {
            final item = displayItems[index];
            final isFavorite = _favoriteIds.contains(item.id);
            
            return _LibraryListItem(
              title: item.title,
              subtitle: item.type == ContentType.hipnosis ? 'Hipnosis' : 'Meditación',
              description: item.description,
              image: item.image,
              isFavorite: isFavorite,
              onTap: () async {
                if (item.downloadUrl == null || item.downloadUrl!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('No hay URL de audio disponible para ${item.title}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Verificar si es una URL de audio
                if (!AudioHelper.isAudioUrl(item.downloadUrl)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('El contenido no tiene un formato de audio válido'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                // Normalizar URL (convertir Google Drive si es necesario)
                final audioUrl = AudioHelper.normalizeAudioUrl(item.downloadUrl);

                final email = context.read<AuthProvider>().user?.email;
                if (email != null && email.isNotEmpty) {
                  final ct = item.type == ContentType.hipnosis ? 'hipnosis' : (item.type == ContentType.meditacion ? 'meditacion' : 'otro');
                  final now = DateTime.now();
                  WordPressService().postActivityLog(
                    email: email,
                    contentId: item.id,
                    contentType: ct,
                    title: item.title,
                    occurredAt: now,
                  );
                  await addActivityItem(email: email, occurredAt: now, contentType: ct, title: item.title);
                }

                showAudioPlayer(
                  context: context,
                  audioUrl: audioUrl,
                  title: item.title,
                );
              },
              onFavoriteTap: () async {
                await _favoritesService.toggleFavorite(item.id);
                await _loadFavorites();
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    final hasSearch = _searchController.text.isNotEmpty;
    final message = hasSearch
        ? 'Aún no tienes este contenido'
        : (_selectedTab == 1
            ? 'No tienes favoritos aún'
            : 'Tu biblioteca está vacía');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasSearch
                ? Icons.search_off
                : (_selectedTab == 1 ? Icons.favorite_border : Icons.folder_open_outlined),
            size: 64,
            color: AppColors.raizSagrada.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTypography.ralewayRegular(
              fontSize: 15,
              color: AppColors.raizSagrada.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Item de lista para biblioteca
class _LibraryListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final String? image;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const _LibraryListItem({
    required this.title,
    this.subtitle,
    this.description,
    this.image,
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
            // Thumbnail con imagen real o placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.raizSagrada.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image != null && image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppColors.raizSagrada.withValues(alpha: 0.15),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ascenso,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppColors.raizSagrada.withValues(alpha: 0.15),
                          child: Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: AppColors.raizSagrada.withValues(alpha: 0.4),
                              size: 24,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: AppColors.raizSagrada.withValues(alpha: 0.4),
                          size: 24,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Título, subtítulo y descripción
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.ralewayRegular(fontSize: 15),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.ralewayLight(
                        fontSize: 12,
                        color: AppColors.raizSagrada.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
                      style: AppTypography.ralewayLight(
                        fontSize: 11,
                        color: AppColors.raizSagrada.withValues(alpha: 0.5),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Corazón verde oliva
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
                  color: isFavorite ? AppColors.ascenso : AppColors.white,
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
