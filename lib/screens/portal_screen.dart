import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../providers/content_provider.dart';
import '../providers/auth_provider.dart';
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
          const SizedBox(height: 8),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final fullName = authProvider.user?.displayName ?? '';
              final firstName = fullName.split(' ').first;
              final capitalizedName = firstName.isNotEmpty
                  ? firstName[0].toUpperCase() + firstName.substring(1)
                  : firstName;
              return Text(
                'Buenas tardes, $capitalizedName',
                style: AppTypography.kaushanTitle(
                  fontSize: 20,
                  color: AppColors.expansionAlquimica,
                ),
              );
            },
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
              const SizedBox(height: 25),
              // Título de sección
              Center(
                child: Text(
                  'Fénix alquimista',
                  textAlign: TextAlign.center,
                  style: AppTypography.kaushanTitle(
                    fontSize: 24,
                    color: AppColors.raizSagrada,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Recursos para almas comprometidas en su camino',
                  textAlign: TextAlign.center,
                  style: AppTypography.ralewayRegular(
                    fontSize: 15,
                    color: AppColors.raizSagrada.withValues(alpha: 0.7),
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 24),
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
          Color tabColor;
          if (isSelected) {
            tabColor = AppColors.raizSagrada; // Tab activo: fondo oscuro
          } else if (index == 1) {
            tabColor = AppColors.ascenso; // HIPNOSIS: azul-verde claro
          } else {
            tabColor = AppColors.expansionAlquimica; // MEDITACIONES: verde oliva
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = index),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: tabColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _tabs[index],
                  style: AppTypography.ralewayBold(
                    fontSize: 13,
                    color: AppColors.white,
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

    // En INICIO solo mostrar la tarjeta destacada, sin listado
    if (_selectedTab == 0) {
      return _buildFeatureCard(items.first);
    }

    // En otras pestañas mostrar tarjeta + listado
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
      margin: EdgeInsets.symmetric(horizontal: _selectedTab == 0 ? 40 : 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Gradiente azul-verde
          Container(
            width: double.infinity,
            height: _selectedTab == 0 ? 300 : 180,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFB0E0E6), // Azul claro
                  Color(0xFF98D8C8), // Verde claro
                ],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'FÉNIX',
                    style: AppTypography.ralewayBold(
                      fontSize: 32,
                      color: AppColors.white,
                    ),
                  ),
                  Text(
                    item.title.contains('Mensajes') ? 'Mensajes del universo' : (item.type == ContentType.hipnosis ? 'Hipnosis' : 'Meditación'),
                    style: AppTypography.kaushanTitle(
                      fontSize: 22,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Wendy Staufert',
                    style: AppTypography.kaushanTitle(
                      fontSize: 14,
                      color: AppColors.expansionAlquimica,
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
                Builder(
                  builder: (context) {
                    // Debug: verificar qué tiene la descripción
                    if (item.description != null) {
                      debugPrint('📝 Descripción encontrada: ${item.description}');
                    } else {
                      debugPrint('⚠️ Descripción es null para: ${item.title}');
                    }
                    
                    final cleanDescription = item.description?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
                    
                    if (cleanDescription.isNotEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            cleanDescription,
                            style: AppTypography.ralewayRegular(
                              fontSize: 13,
                              color: AppColors.raizSagrada.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 12),
                // Botones
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _onItemTap(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.ascenso,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.book_outlined,
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
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ascenso,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_outline,
                            color: AppColors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Gratuito',
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
