import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/content_provider.dart';
import '../services/wordpress_service.dart';
import '../widgets/content_card.dart';
import '../widgets/audio_player_modal.dart';
import '../utils/audio_helper.dart';

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
          _buildHeader(),
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
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        // Filtrar contenido según pestaña
        final items = _getFilteredItems(provider);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _buildTabs(),
              const SizedBox(height: 20),
              // Título de sección
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Fénix alquimista',
                  style: AppTypography.kaushanTitle(
                    fontSize: 24,
                    color: AppColors.expansionAlquimica,
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
              // Mostrar contenido o estado vacío
              if (provider.isLoading)
                _buildLoading()
              else if (items.isEmpty)
                _buildEmptyState()
              else
                _buildContentList(items),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  List<ContentItem> _getFilteredItems(ContentProvider provider) {
    switch (_selectedTab) {
      case 0: // INICIO - Todo
        return provider.all;
      case 1: // HIPNOSIS
        return provider.hypnosis;
      case 2: // MEDITACIONES
        return provider.meditations;
      default:
        return provider.all;
    }
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

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Center(
        child: CircularProgressIndicator(
          color: AppColors.ascenso,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    switch (_selectedTab) {
      case 1:
        message = 'No tienes hipnosis en tu biblioteca';
        break;
      case 2:
        message = 'No tienes meditaciones en tu biblioteca';
        break;
      default:
        message = 'Tu biblioteca está vacía';
    }

    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.folder_open_outlined,
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentList(List<ContentItem> items) {
    // Mostrar primer item como destacado si hay contenido
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        // Card destacado con el primer item
        _buildFeatureCard(items.first),
        const SizedBox(height: 24),
        // Lista del resto
        ...items.skip(1).map((item) => ContentListItem(
          title: item.title,
          subtitle: item.type == ContentType.hipnosis ? 'Hipnosis' : 'Meditación',
          onTap: () => _onItemTap(item),
          onFavoriteTap: () {},
        )),
      ],
    );
  }

  Widget _buildFeatureCard(ContentItem item) {
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
                    item.type == ContentType.hipnosis ? 'Hipnosis' : 'Meditación',
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
                  item.title,
                  style: AppTypography.ralewayBold(
                    fontSize: 16,
                    color: AppColors.raizSagrada,
                  ),
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    style: AppTypography.ralewayRegular(
                      fontSize: 13,
                      color: AppColors.raizSagrada.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                // Botón reproducir
                GestureDetector(
                  onTap: () => _onItemTap(item),
                  child: Container(
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
                          Icons.play_circle_outline,
                          color: AppColors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Reproducir',
                          style: AppTypography.ralewayBold(
                            fontSize: 12,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTap(ContentItem item) {
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
    
    // Abrir reproductor de audio
    showAudioPlayer(
      context: context,
      audioUrl: audioUrl,
      title: item.title,
    );
  }
}
