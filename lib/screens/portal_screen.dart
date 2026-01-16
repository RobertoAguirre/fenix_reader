import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
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
    AppConstants.programasFenix,
    AppConstants.thetaFenix,
    AppConstants.consultaExpres,
    AppConstants.sesionFenix,
    AppConstants.sesionFenixNinos,
  ];
  
  // Estado para THETAFENIX
  List<Map<String, dynamic>> _thetaFenixSessions = [];
  bool _isLoadingThetaFenix = false;
  Map<String, dynamic>? _thetaFenixPageInfo;

  @override
  void initState() {
    super.initState();
    // Cargar programas cuando se monta el widget
    _loadProgramsIfNeeded();
  }

  void _loadProgramsIfNeeded() {
    final authProvider = context.read<AuthProvider>();
    final email = authProvider.user?.email;
    if (email != null && _selectedTab == 3) {
      context.read<ContentProvider>().loadUserPrograms(email);
    }
  }

  /// Limpia descripciones de palabras prohibidas (membresías, compras, etc.)
  String _cleanDescription(String? description) {
    if (description == null || description.isEmpty) {
      return '';
    }

    // Remover HTML
    String cleaned = description.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    
    // Lista de palabras prohibidas (case insensitive)
    final prohibitedWords = [
      'membresía',
      'membresia',
      'membresías',
      'membresias',
      'comprar',
      'compra',
      'compras',
      'adquirir',
      'adquiere',
      'adquiere',
      'pago',
      'pagos',
      'precio',
      'precios',
      'costo',
      'costos',
      'tarifa',
      'tarifas',
      'suscripción',
      'suscripcion',
      'suscripciones',
      'suscripciones',
      'plan',
      'planes',
      'paquete',
      'paquetes',
    ];

    // Remover frases que contengan palabras prohibidas
    final sentences = cleaned.split(RegExp(r'[.!?]\s+'));
    final allowedSentences = sentences.where((sentence) {
      final lowerSentence = sentence.toLowerCase();
      return !prohibitedWords.any((word) => lowerSentence.contains(word.toLowerCase()));
    }).toList();

    cleaned = allowedSentences.join('. ').trim();
    
    // Limpiar espacios múltiples
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.raizSagrada,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.origen,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: _buildContent(),
            ),
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
        // Cargar programas si se selecciona la pestaña
        if (_selectedTab == 3) {
          final authProvider = context.read<AuthProvider>();
          final email = authProvider.user?.email;
          if (email != null && provider.programs.isEmpty && !provider.isLoadingPrograms) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.loadUserPrograms(email);
            });
          }
        }
        
        // Cargar sesiones de THETAFENIX si se selecciona la pestaña
        if (_selectedTab == 4 && _thetaFenixSessions.isEmpty && !_isLoadingThetaFenix) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadThetaFenixSessions();
          });
        }

        // Filtrar contenido según pestaña
        final items = _getFilteredItems(provider);
        final isLoading = _selectedTab == 3 
            ? provider.isLoadingPrograms 
            : (_selectedTab == 4 ? _isLoadingThetaFenix : provider.isLoading);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 22),
              _buildTabs(),
              const SizedBox(height: 27),
              // Título de sección - Usa el título de la pestaña seleccionada
              Center(
                child: Text(
                  _tabs[_selectedTab],
                  textAlign: TextAlign.center,
                  style: AppTypography.kaushanTitle(
                    fontSize: 24,
                    color: AppColors.raizSagrada,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 2),
              // Mostrar contenido o estado vacío
              if (isLoading)
                _buildLoading()
              else if (_selectedTab == 3)
                _buildProgramsList(provider.programs)
              else if (_selectedTab == 4)
                _buildThetaFenixContent()
              else if (_selectedTab == 5)
                _buildConsultaExpresContent()
              else if (_selectedTab == 6)
                _buildSesionFenixContent()
              else if (_selectedTab == 7)
                _buildSesionFenixNinosContent()
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
      case 3: // PROGRAMAS FÉNIX - Se maneja separadamente
        return [];
      case 4: // THETAFENIX - Se maneja separadamente
        return [];
      case 5: // CONSULTA EXPRÉS - Se maneja separadamente
        return [];
      case 6: // SESIÓN FÉNIX - Se maneja separadamente
        return [];
      case 7: // SESIÓN FÉNIX NIÑOS - Se maneja separadamente
        return [];
      default:
        return provider.all;
    }
  }

  /// Convertir programa a ContentItem para mostrar en grid
  ContentItem _programToContentItem(Map<String, dynamic> program) {
    return ContentItem(
      id: program['ID'] as int? ?? program['id'] as int? ?? 0,
      title: program['post_title'] as String? ?? program['title'] as String? ?? 'Sin título',
      description: _cleanDescription(program['post_excerpt'] as String? ?? program['description'] as String?),
      image: program['featuredImage'] as String? ?? program['image'] as String?,
      downloadUrl: null, // Los programas no tienen downloadUrl directo
    );
  }

  Widget _buildProgramsList(List<Map<String, dynamic>> programs) {
    if (programs.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: programs.length,
        itemBuilder: (context, index) {
          final program = programs[index];
          return _buildProgramGridCard(program);
        },
      ),
    );
  }

  Widget _buildProgramGridCard(Map<String, dynamic> program) {
    final title = program['post_title'] as String? ?? program['title'] as String? ?? 'Sin título';
    final image = program['featuredImage'] as String? ?? program['image'] as String?;
    
    return GestureDetector(
      onTap: () => _showProgramModal(program),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.raizSagrada.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: image != null && image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFB0E0E6),
                                Color(0xFF98D8C8),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildGradientFallbackForProgram(program),
                      )
                    : _buildGradientFallbackForProgram(program),
              ),
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.ralewayBold(
                          fontSize: 13,
                          color: AppColors.raizSagrada,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientFallbackForProgram(Map<String, dynamic> program) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB0E0E6),
            Color(0xFF98D8C8),
          ],
        ),
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
              'Programa',
              style: AppTypography.kaushanTitle(
                fontSize: 22,
                color: AppColors.white,
              ),
            ),
          ],
        ),
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
          Color tabColor;
          if (isSelected) {
            tabColor = AppColors.raizSagrada; // Tab activo: fondo oscuro
          } else if (index == 1) {
            tabColor = AppColors.ascenso; // HIPNOSIS: azul-verde claro
          } else if (index == 2) {
            tabColor = AppColors.expansionAlquimica; // MEDITACIONES: verde oliva
          } else if (index == 4) {
            tabColor = AppColors.expansionAlquimica; // THETAFENIX: verde oliva
          } else if (index == 5) {
            tabColor = AppColors.expansionAlquimica; // CONSULTA EXPRÉS: verde oliva
          } else if (index == 6) {
            tabColor = AppColors.expansionAlquimica; // SESIÓN FÉNIX: verde oliva
          } else if (index == 7) {
            tabColor = AppColors.expansionAlquimica; // SESIÓN FÉNIX NIÑOS: verde oliva
          } else {
            tabColor = AppColors.ascenso; // Otras pestañas: azul-verde claro
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = index);
                // Cargar programas si se selecciona esa pestaña
                if (index == 3) {
                  final authProvider = context.read<AuthProvider>();
                  final email = authProvider.user?.email;
                  if (email != null) {
                    context.read<ContentProvider>().loadUserPrograms(email);
                  }
                }
                // Cargar sesiones de THETAFENIX si se selecciona esa pestaña
                if (index == 4) {
                  _loadThetaFenixSessions();
                }
              },
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
      case 3:
        message = 'No tienes programas en tu biblioteca';
        break;
      case 4:
        message = 'No hay sesiones disponibles en este momento';
        break;
      case 5:
        message = 'Consulta exprés disponible';
        break;
      case 6:
        message = 'Sesión Fénix disponible';
        break;
      case 7:
        message = 'Sesión Fénix Niños disponible';
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

    // En otras pestañas mostrar grid de 2 columnas
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildGridCard(item);
        },
      ),
    );
  }

  Widget _buildGridCard(ContentItem item) {
    return GestureDetector(
      onTap: () => _showContentModal(item),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.raizSagrada.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 1,
                child: item.image != null && item.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.image!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFB0E0E6),
                                Color(0xFF98D8C8),
                              ],
                            ),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildGradientFallback(item),
                      )
                    : _buildGradientFallback(item),
              ),
            ),
            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        item.title,
                        style: AppTypography.ralewayBold(
                          fontSize: 13,
                          color: AppColors.raizSagrada,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientFallback(ContentItem item) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFB0E0E6), // Azul claro
            Color(0xFF98D8C8), // Verde claro
          ],
        ),
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
          // Imagen del contenido o gradiente como fallback
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              width: double.infinity,
              height: _selectedTab == 0 ? 300 : 180,
              child: item.image != null && item.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFB0E0E6),
                              Color(0xFF98D8C8),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildGradientFallback(item),
                    )
                  : _buildGradientFallback(item),
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
                    final cleanDescription = _cleanDescription(item.description);
                    
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
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
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
                              Icons.play_arrow,
                              color: AppColors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Escuchar',
                              style: AppTypography.ralewayBold(
                                fontSize: 12,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botón "Gratuito" comentado para evitar implicar contenido de pago
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 12,
                    //     vertical: 10,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: AppColors.ascenso,
                    //     borderRadius: BorderRadius.circular(8),
                    //   ),
                    //   child: Row(
                    //     mainAxisSize: MainAxisSize.min,
                    //     children: [
                    //       const Icon(
                    //         Icons.star_outline,
                    //         color: AppColors.white,
                    //         size: 16,
                    //       ),
                    //       const SizedBox(width: 6),
                    //       Text(
                    //         'Gratuito',
                    //         style: AppTypography.ralewayBold(
                    //           fontSize: 12,
                    //           color: AppColors.white,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContentModal(ContentItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: AppColors.origen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Barra superior con botón cerrar
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.raizSagrada,
                    ),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
            ),
            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildModalFeatureCard(item, modalContext),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalFeatureCard(ContentItem item, BuildContext modalContext) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
          // Imagen del contenido o gradiente como fallback
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              width: double.infinity,
              height: 300,
              child: item.image != null && item.image!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.image!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFFB0E0E6),
                              Color(0xFF98D8C8),
                            ],
                          ),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildGradientFallback(item),
                    )
                  : _buildGradientFallback(item),
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
                    final cleanDescription = _cleanDescription(item.description);
                    
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
                // Botón Escuchar
                GestureDetector(
                  onTap: () {
                    Navigator.pop(modalContext);
                    _onItemTap(item);
                  },
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
                          Icons.play_arrow,
                          color: AppColors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Escuchar',
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

  void _showProgramModal(Map<String, dynamic> program) async {
    final courseId = program['ID'] as int? ?? program['id'] as int?;
    if (courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cargar el programa'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.ascenso),
      ),
    );

    try {
      // Obtener detalles del programa
      final wpService = WordPressService();
      final details = await wpService.getTutorCourseDetails(courseId);
      
      if (!context.mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (details == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron cargar los detalles del programa'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      // Mostrar modal con el contenido del programa
      if (context.mounted) {
        _showProgramDetailsModal(program, details);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Cerrar loading si aún está abierto
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el programa: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showProgramDetailsModal(Map<String, dynamic> program, Map<String, dynamic> details) {
    final title = program['post_title'] as String? ?? program['title'] as String? ?? 'Programa';
    final topics = details['topics'] as List<dynamic>? ?? [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: AppColors.origen,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Barra superior
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.raizSagrada,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.kaushanTitle(
                        fontSize: 20,
                        color: AppColors.raizSagrada,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.raizSagrada,
                    ),
                    onPressed: () => Navigator.pop(modalContext),
                  ),
                ],
              ),
            ),
            // Contenido scrolleable
            Expanded(
              child: topics.isEmpty
                  ? Center(
                      child: Text(
                        'El programa no tiene contenido disponible',
                        style: AppTypography.ralewayRegular(
                          fontSize: 14,
                          color: AppColors.raizSagrada.withValues(alpha: 0.6),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: topics.length,
                      itemBuilder: (context, index) {
                        final topic = topics[index] as Map<String, dynamic>;
                        return _buildProgramTopic(topic, modalContext);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramTopic(Map<String, dynamic> topic, BuildContext modalContext) {
    final topicTitle = topic['post_title'] as String? ?? 'Sin título';
    final lessons = topic['lessons'];
    List<dynamic> lessonsList = [];
    
    if (lessons != null) {
      if (lessons is Map && lessons['data'] != null) {
        lessonsList = lessons['data'] as List<dynamic>? ?? [];
      } else if (lessons is List) {
        lessonsList = lessons;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.raizSagrada.withValues(alpha: 0.1),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          topicTitle,
          style: AppTypography.ralewayBold(
            fontSize: 15,
            color: AppColors.raizSagrada,
          ),
        ),
        children: lessonsList.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No hay lecciones disponibles',
                    style: AppTypography.ralewayRegular(
                      fontSize: 13,
                      color: AppColors.raizSagrada.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ]
            : lessonsList.map((lesson) {
                final lessonMap = lesson as Map<String, dynamic>;
                return _buildProgramLesson(lessonMap, modalContext);
              }).toList(),
      ),
    );
  }

  Widget _buildProgramLesson(Map<String, dynamic> lesson, BuildContext modalContext) {
    final lessonTitle = lesson['post_title'] as String? ?? 'Sin título';
    final vimeoCode = lesson['vimeo_embed_code'] as String? ?? lesson['embed_code'] as String?;
    final postContent = lesson['post_content'] as String? ?? '';
    final isPdf = postContent.endsWith('.pdf');
    final hasVideo = vimeoCode != null && vimeoCode.isNotEmpty;

    return ListTile(
      leading: Icon(
        isPdf ? Icons.picture_as_pdf : (hasVideo ? Icons.play_circle_outline : Icons.description),
        color: AppColors.ascenso,
      ),
      title: Text(
        lessonTitle,
        style: AppTypography.ralewayRegular(
          fontSize: 14,
          color: AppColors.raizSagrada,
        ),
      ),
      onTap: () {
        if (isPdf) {
          // TODO: Abrir PDF con visor nativo
          ScaffoldMessenger.of(modalContext).showSnackBar(
            const SnackBar(
              content: Text('Funcionalidad de PDF próximamente'),
              backgroundColor: AppColors.ascenso,
            ),
          );
        } else if (hasVideo) {
          // TODO: Reproducir video de Vimeo nativamente
          ScaffoldMessenger.of(modalContext).showSnackBar(
            const SnackBar(
              content: Text('Funcionalidad de video próximamente'),
              backgroundColor: AppColors.ascenso,
            ),
          );
        }
      },
    );
  }

  /// Cargar sesiones de THETAFENIX
  Future<void> _loadThetaFenixSessions() async {
    if (_isLoadingThetaFenix) return;
    
    setState(() {
      _isLoadingThetaFenix = true;
    });

    try {
      final wpService = WordPressService();
      final data = await wpService.getThetaFenixSessions();
      
      setState(() {
        final sessionsData = data['sessions'];
        if (sessionsData is List) {
          _thetaFenixSessions = sessionsData
              .whereType<Map<String, dynamic>>()
              .toList();
        } else {
          _thetaFenixSessions = [];
        }
        final pageInfoData = data['pageInfo'];
        _thetaFenixPageInfo = pageInfoData is Map<String, dynamic> ? pageInfoData : null;
        _isLoadingThetaFenix = false;
      });
    } catch (e) {
      debugPrint('❌ Error cargando sesiones de THETAFENIX: $e');
      setState(() {
        _isLoadingThetaFenix = false;
      });
    }
  }

  /// Construir contenido de THETAFENIX
  Widget _buildThetaFenixContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video de YouTube promocional
          _buildThetaFenixVideo(),
          const SizedBox(height: 20),
          
          // Información de la sesión
          Text(
            'Modalidad Online',
            style: AppTypography.ralewayBold(
              fontSize: 16,
              color: AppColors.raizSagrada,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Duración: 90 min',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hora: 8:30pm CDMX',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          
          // Lista de sesiones
          if (_thetaFenixSessions.isEmpty)
            Text(
              'No hay sesiones disponibles en este momento',
              style: AppTypography.ralewayRegular(
                fontSize: 14,
                color: AppColors.raizSagrada.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 18,
              children: _thetaFenixSessions.map((session) {
                return Container(
                  width: (MediaQuery.of(context).size.width - 52) / 2,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.raizSagrada.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${session['dayName']} ${_formatThetaDate(session['date'] as String)}',
                        style: AppTypography.ralewayBold(
                          fontSize: 16,
                          color: AppColors.raizSagrada,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// Construir widget de video de YouTube para THETAFENIX
  Widget _buildThetaFenixVideo() {
    return _ThetaFenixVideoPlayer(videoUrl: AppConstants.thetaFenixVideoUrl);
  }

  /// Construir contenido de CONSULTA EXPRÉS
  Widget _buildConsultaExpresContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Un espacio seguro y profesional, justo cuando más lo necesitas.',
            style: AppTypography.kaushanTitle(
              fontSize: 20,
              color: AppColors.raizSagrada,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Video promocional
          _ConsultaExpresVideoPlayer(videoUrl: AppConstants.consultaExpresVideoUrl),
          const SizedBox(height: 20),
          
          // Descripción
          Text(
            'Aquí no estás solx: estoy para escucharte, guiarte y darte claridad para recuperar tu equilibrio.',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          // Botón de apoyo de emergencia
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _openWhatsAppConsulta,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ascenso,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Apoyo de emergencia',
                      style: AppTypography.ralewayBold(
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Soporte oportuno disponible',
                  style: AppTypography.ralewayRegular(
                    fontSize: 12,
                    color: AppColors.raizSagrada.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Abrir WhatsApp para contactar
  Future<void> _openWhatsAppConsulta() async {
    try {
      final message = Uri.encodeComponent(AppConstants.whatsappConsultaMessage);
      final whatsappUrl = 'https://api.whatsapp.com/send?phone=${AppConstants.whatsappNumber}&text=$message';
      final uri = Uri.parse(whatsappUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir WhatsApp. Por favor, verifica que tengas WhatsApp instalado.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error abriendo WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al abrir WhatsApp'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Formatear fecha de THETAFENIX
  String _formatThetaDate(String dateString) {
    final months = {
      'Enero': 'Ene',
      'Febrero': 'Feb',
      'Marzo': 'Mar',
      'Abril': 'Abr',
      'Mayo': 'May',
      'Junio': 'Jun',
      'Julio': 'Jul',
      'Agosto': 'Ago',
      'Septiembre': 'Sep',
      'Octubre': 'Oct',
      'Noviembre': 'Nov',
      'Diciembre': 'Dic',
    };

    final parts = dateString.split(' ');
    if (parts.length >= 2) {
      final day = parts[0];
      final month = parts[1];
      final monthShort = months[month] ?? month;
      return '$day $monthShort';
    }
    return dateString;
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

  /// Construir contenido de SESIÓN FÉNIX
  Widget _buildSesionFenixContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            '¿Qué pasaría si dejaras de sobrevivir y empezaras a vivir?',
            style: AppTypography.kaushanTitle(
              fontSize: 20,
              color: AppColors.raizSagrada,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Video promocional
          _SesionFenixVideoPlayer(videoUrl: AppConstants.sesionFenixVideoUrl),
          const SizedBox(height: 20),
          
          // Descripción
          Text(
            'La transformación no duele.',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Resistirse, sí.',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Información de la sesión
          Text(
            'Modalidad Online',
            style: AppTypography.ralewayBold(
              fontSize: 16,
              color: AppColors.raizSagrada,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Para personas mayores de 12 años',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Construir contenido de SESIÓN FÉNIX NIÑOS
  Widget _buildSesionFenixNinosContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Alinearse y liberar desde pequeños nunca fué tan fácil.',
            style: AppTypography.kaushanTitle(
              fontSize: 20,
              color: AppColors.raizSagrada,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Video promocional
          _SesionFenixNinosVideoPlayer(videoUrl: AppConstants.sesionFenixNinosVideoUrl),
          const SizedBox(height: 20),
          
          // Descripción
          Text(
            'Confía.',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Sanar es posible, incluso en los más pequeños.',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Información de la sesión
          Text(
            'Modalidad Online',
            style: AppTypography.ralewayBold(
              fontSize: 16,
              color: AppColors.raizSagrada,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Para niños menores de 12 años',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Widget para reproducir video de YouTube de forma nativa (SESIÓN FÉNIX)
class _SesionFenixVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _SesionFenixVideoPlayer({required this.videoUrl});

  @override
  State<_SesionFenixVideoPlayer> createState() => _SesionFenixVideoPlayerState();
}

class _SesionFenixVideoPlayerState extends State<_SesionFenixVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Forzar orientación portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Extraer ID del video de YouTube de la URL embebida
      final videoIdMatch = RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)').firstMatch(widget.videoUrl);
      if (videoIdMatch == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      final videoId = videoIdMatch.group(1)!;
      
      // Usar YoutubeExplode para obtener la URL directa del video
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streams.getManifest(videoId);
      
      // Obtener el stream de mejor calidad disponible
      VideoStreamInfo? streamInfo;
      
      // Preferir muxed (audio+video) si está disponible, sino usar videoOnly
      if (manifest.muxed.isNotEmpty) {
        // Tomar el último stream muxed (suele ser el de mayor calidad)
        streamInfo = manifest.muxed.last;
      } else if (manifest.videoOnly.isNotEmpty) {
        // Tomar el último stream videoOnly (suele ser el de mayor calidad)
        streamInfo = manifest.videoOnly.last;
      }
      
      if (streamInfo == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        yt.close();
        return;
      }

      // Crear controlador de video con la URL directa (streamInfo.url ya es Uri)
      _controller = VideoPlayerController.networkUrl(streamInfo.url);

      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        showControls: true,
        allowFullScreen: false, // Deshabilitar pantalla completa para evitar problemas de orientación
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error al cargar el video',
              style: AppTypography.ralewayRegular(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          );
        },
      );

      yt.close();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error cargando video de YouTube: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Restaurar todas las orientaciones permitidas
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 225,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.raizSagrada.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.ascenso,
                ),
              )
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.raizSagrada.withValues(alpha: 0.6),
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar el video',
                          style: AppTypography.ralewayRegular(
                            fontSize: 14,
                            color: AppColors.raizSagrada.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const SizedBox.shrink(),
      ),
    );
  }
}

/// Widget para reproducir video de YouTube de forma nativa (SESIÓN FÉNIX NIÑOS)
class _SesionFenixNinosVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _SesionFenixNinosVideoPlayer({required this.videoUrl});

  @override
  State<_SesionFenixNinosVideoPlayer> createState() => _SesionFenixNinosVideoPlayerState();
}

class _SesionFenixNinosVideoPlayerState extends State<_SesionFenixNinosVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Forzar orientación portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Extraer ID del video de YouTube de la URL embebida
      final videoIdMatch = RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)').firstMatch(widget.videoUrl);
      if (videoIdMatch == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      final videoId = videoIdMatch.group(1)!;
      
      // Usar YoutubeExplode para obtener la URL directa del video
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streams.getManifest(videoId);
      
      // Obtener el stream de mejor calidad disponible
      VideoStreamInfo? streamInfo;
      
      // Preferir muxed (audio+video) si está disponible, sino usar videoOnly
      if (manifest.muxed.isNotEmpty) {
        // Tomar el último stream muxed (suele ser el de mayor calidad)
        streamInfo = manifest.muxed.last;
      } else if (manifest.videoOnly.isNotEmpty) {
        // Tomar el último stream videoOnly (suele ser el de mayor calidad)
        streamInfo = manifest.videoOnly.last;
      }
      
      if (streamInfo == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        yt.close();
        return;
      }

      // Crear controlador de video con la URL directa (streamInfo.url ya es Uri)
      _controller = VideoPlayerController.networkUrl(streamInfo.url);

      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        showControls: true,
        allowFullScreen: false, // Deshabilitar pantalla completa para evitar problemas de orientación
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error al cargar el video',
              style: AppTypography.ralewayRegular(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          );
        },
      );

      yt.close();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error cargando video de YouTube: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Restaurar todas las orientaciones permitidas
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 225,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.raizSagrada.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.ascenso,
                ),
              )
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.raizSagrada.withValues(alpha: 0.6),
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar el video',
                          style: AppTypography.ralewayRegular(
                            fontSize: 14,
                            color: AppColors.raizSagrada.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const SizedBox.shrink(),
      ),
    );
  }
}

/// Widget para reproducir video de YouTube de forma nativa (CONSULTA EXPRÉS)
class _ConsultaExpresVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _ConsultaExpresVideoPlayer({required this.videoUrl});

  @override
  State<_ConsultaExpresVideoPlayer> createState() => _ConsultaExpresVideoPlayerState();
}

class _ConsultaExpresVideoPlayerState extends State<_ConsultaExpresVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Forzar orientación portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Extraer ID del video de YouTube de la URL embebida
      final videoIdMatch = RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)').firstMatch(widget.videoUrl);
      if (videoIdMatch == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      final videoId = videoIdMatch.group(1)!;
      
      // Usar YoutubeExplode para obtener la URL directa del video
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streams.getManifest(videoId);
      
      // Obtener el stream de mejor calidad disponible
      VideoStreamInfo? streamInfo;
      
      // Preferir muxed (audio+video) si está disponible, sino usar videoOnly
      if (manifest.muxed.isNotEmpty) {
        // Tomar el último stream muxed (suele ser el de mayor calidad)
        streamInfo = manifest.muxed.last;
      } else if (manifest.videoOnly.isNotEmpty) {
        // Tomar el último stream videoOnly (suele ser el de mayor calidad)
        streamInfo = manifest.videoOnly.last;
      }
      
      if (streamInfo == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        yt.close();
        return;
      }

      // Crear controlador de video con la URL directa (streamInfo.url ya es Uri)
      _controller = VideoPlayerController.networkUrl(streamInfo.url);

      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        showControls: true,
        allowFullScreen: false, // Deshabilitar pantalla completa para evitar problemas de orientación
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error al cargar el video',
              style: AppTypography.ralewayRegular(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          );
        },
      );

      yt.close();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error cargando video de YouTube: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Restaurar todas las orientaciones permitidas
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 225,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.raizSagrada.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.ascenso,
                ),
              )
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.raizSagrada.withValues(alpha: 0.6),
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar el video',
                          style: AppTypography.ralewayRegular(
                            fontSize: 14,
                            color: AppColors.raizSagrada.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const SizedBox.shrink(),
      ),
    );
  }
}

/// Widget para reproducir video de YouTube de forma nativa
class _ThetaFenixVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _ThetaFenixVideoPlayer({required this.videoUrl});

  @override
  State<_ThetaFenixVideoPlayer> createState() => _ThetaFenixVideoPlayerState();
}

class _ThetaFenixVideoPlayerState extends State<_ThetaFenixVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    // Forzar orientación portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Extraer ID del video de YouTube de la URL embebida
      final videoIdMatch = RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)').firstMatch(widget.videoUrl);
      if (videoIdMatch == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      final videoId = videoIdMatch.group(1)!;
      
      // Usar YoutubeExplode para obtener la URL directa del video
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streams.getManifest(videoId);
      
      // Obtener el stream de mejor calidad disponible
      // Muxed tiene audio+video pero limitado a 360p, videoOnly puede tener mejor calidad
      VideoStreamInfo? streamInfo;
      
      // Preferir muxed (audio+video) si está disponible, sino usar videoOnly
      if (manifest.muxed.isNotEmpty) {
        // Tomar el último stream muxed (suele ser el de mayor calidad)
        streamInfo = manifest.muxed.last;
      } else if (manifest.videoOnly.isNotEmpty) {
        // Tomar el último stream videoOnly (suele ser el de mayor calidad)
        streamInfo = manifest.videoOnly.last;
      }
      
      if (streamInfo == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        yt.close();
        return;
      }

      // Crear controlador de video con la URL directa (streamInfo.url ya es Uri)
      _controller = VideoPlayerController.networkUrl(streamInfo.url);

      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        showControls: true,
        allowFullScreen: false, // Deshabilitar pantalla completa para evitar problemas de orientación
        allowMuting: true,
        allowPlaybackSpeedChanging: false,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error al cargar el video',
              style: AppTypography.ralewayRegular(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          );
        },
      );

      yt.close();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error cargando video de YouTube: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Restaurar todas las orientaciones permitidas
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 225,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.raizSagrada.withValues(alpha: 0.1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.ascenso,
                ),
              )
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.raizSagrada.withValues(alpha: 0.6),
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar el video',
                          style: AppTypography.ralewayRegular(
                            fontSize: 14,
                            color: AppColors.raizSagrada.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : _chewieController != null
                    ? Chewie(controller: _chewieController!)
                    : const SizedBox.shrink(),
      ),
    );
  }
}
