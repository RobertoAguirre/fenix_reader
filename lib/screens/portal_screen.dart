import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
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
import '../services/wordpress_service.dart' show WordPressService, ContentItem, ContentType, UserContent, VimeoService;
import '../widgets/content_card.dart';
import '../widgets/audio_player_modal.dart';
import '../widgets/video_player_modal.dart';
import '../utils/audio_helper.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as html_dom;
import 'package:flutter_screenshot_blocker/flutter_screenshot_blocker.dart';
import '../services/favorites_service.dart';

/// Pantalla de Portales/Inicio con tabs
class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  int _selectedTab = 0;
  final _tabs = [
    AppConstants.portals, // Portales
    AppConstants.hypnosisFenix,
    AppConstants.meditationsFenix,
    AppConstants.tappings,
    AppConstants.thetaFenix,
    AppConstants.programasFenix,
    AppConstants.consultaExpres,
    AppConstants.sesionFenix,
  ];
  
  // Estado para THETAFENIX
  List<Map<String, dynamic>> _thetaFenixSessions = [];
  bool _isLoadingThetaFenix = false;
  Map<String, dynamic>? _thetaFenixPageInfo;
  
  // Estado para HIPNOSIS FÉNIX
  final TextEditingController _hypnosisSearchController = TextEditingController();
  final FavoritesService _favoritesService = FavoritesService();
  Set<int> _favoriteIds = {};
  bool _showFavoritesOnly = false;
  
  // Estado para MEDITACIONES FÉNIX
  final TextEditingController _meditationsSearchController = TextEditingController();
  bool _showMeditationsFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    // Cargar programas cuando se monta el widget
    _loadProgramsIfNeeded();
    // Cargar favoritos cuando se monta el widget
    _loadFavorites();
  }

  @override
  void dispose() {
    _hypnosisSearchController.dispose();
    _meditationsSearchController.dispose();
    super.dispose();
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
                textAlign: TextAlign.center,
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
        final isLoading = _selectedTab == 5 
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
                  _selectedTab == 1 
                      ? 'Hipnosis Fénix' 
                      : (_selectedTab == 2 ? 'Meditaciones Fénix' : _tabs[_selectedTab]),
                  textAlign: TextAlign.center,
                  style: AppTypography.kaushanTitle(
                    fontSize: 24,
                    color: AppColors.raizSagrada,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Mostrar contenido o estado vacío
              if (isLoading)
                _buildLoading()
              else if (_selectedTab == 0)
                _buildPortalesContent()
              else if (_selectedTab == 1)
                _buildHypnosisFenixContent(provider)
              else if (_selectedTab == 2)
                _buildMeditationsFenixContent(provider)
              else if (_selectedTab == 3)
                _buildTappingsContent()
              else if (_selectedTab == 4)
                _buildThetaFenixContent()
              else if (_selectedTab == 5)
                _buildProgramsList(provider.programs)
              else if (_selectedTab == 6)
                _buildConsultaExpresContent()
              else if (_selectedTab == 7)
                _buildSesionFenixContent()
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
      case 3: // TAPPINGS - Se maneja separadamente
        return [];
      case 4: // THETAFENIX - Se maneja separadamente
        return [];
      case 5: // PROGRAMAS FÉNIX - Se maneja separadamente
        return [];
      case 6: // CONSULTA EXPRÉS - Se maneja separadamente
        return [];
      case 7: // SESIÓN FÉNIX - Se maneja separadamente
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
          } else if (index == 3) {
            tabColor = AppColors.expansionAlquimica; // TAPPINGS: verde oliva
          } else if (index == 4) {
            tabColor = AppColors.expansionAlquimica; // THETAFENIX: verde oliva
          } else if (index == 5) {
            tabColor = AppColors.expansionAlquimica; // PROGRAMAS FÉNIX: verde oliva
          } else if (index == 6) {
            tabColor = AppColors.expansionAlquimica; // CONSULTA EXPRÉS: verde oliva
          } else if (index == 7) {
            tabColor = AppColors.expansionAlquimica; // SESIÓN FÉNIX: verde oliva
          } else {
            tabColor = AppColors.ascenso; // Otras pestañas: azul-verde claro
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedTab = index);
                // Cargar programas si se selecciona esa pestaña
                if (index == 5) {
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
        message = 'No tienes Tappings disponibles';
        break;
      case 4:
        message = 'No hay sesiones disponibles en este momento';
        break;
      case 5:
        message = 'No tienes programas en tu biblioteca';
        break;
      case 6:
        message = 'Primeros auxilios disponible';
        break;
      case 7:
        message = 'Sesión Fénix disponible';
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

  /// Construir contenido de PORTALES (Tab 0)
  Widget _buildPortalesContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Fénix alquimista',
            style: AppTypography.kaushanTitle(
              fontSize: 24,
              color: AppColors.expansionAlquimica,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Descripción
          Text(
            'Recursos exclusivos para almas comprometidas en su camino.',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Video promocional
          _PortalesVideoPlayer(videoUrl: AppConstants.portalesVideoUrl),
          const SizedBox(height: 24),
          
          // Lista de documentos
          _buildDocumentsList(),
          const SizedBox(height: 24),
          
          // Botón Apoyo Fénix
          Center(
            child: GestureDetector(
              onTap: _openWhatsAppApoyo,
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
                  'Apoyo Fénix',
                  style: AppTypography.kaushanTitle(
                    fontSize: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Construir contenido de HIPNOSIS FÉNIX
  Widget _buildHypnosisFenixContent(ContentProvider provider) {
    final allItems = provider.hypnosis;
    final filteredItems = _getFilteredHypnosisItems(allItems);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Activa tu frecuencia',
            style: AppTypography.kaushanTitle(
              fontSize: 24,
              color: AppColors.expansionAlquimica,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Video promocional
          _PortalesVideoPlayer(videoUrl: AppConstants.hypnosisFenixVideoUrl),
          const SizedBox(height: 16),
          
          // Texto descriptivo
          Text(
            'Se reproduce con audífonos si duermes acompañadx y te duermes con ella.',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Buscador y filtro de favoritos
          _buildHypnosisSearchBar(),
          const SizedBox(height: 8),
          
          // Grid de hipnosis
          if (filteredItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _showFavoritesOnly 
                      ? 'No tienes favoritos aún'
                      : 'No se encontraron resultados',
                  style: AppTypography.ralewayRegular(
                    fontSize: 14,
                    color: AppColors.raizSagrada.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
            _buildHypnosisGrid(filteredItems),
          const SizedBox(height: 24),
          
          // Botón Apoyo Fénix
          Center(
            child: GestureDetector(
              onTap: _openWhatsAppApoyo,
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
                  'Apoyo Fénix',
                  style: AppTypography.kaushanTitle(
                    fontSize: 16,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Buscador y filtro de favoritos para Hipnosis
  Widget _buildHypnosisSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.raizSagrada.withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              controller: _hypnosisSearchController,
              decoration: InputDecoration(
                hintText: 'Buscar hipnosis...',
                hintStyle: AppTypography.ralewayRegular(
                  fontSize: 14,
                  color: AppColors.raizSagrada.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.raizSagrada.withValues(alpha: 0.5),
                ),
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
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _showFavoritesOnly = !_showFavoritesOnly;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _showFavoritesOnly 
                  ? AppColors.expansionAlquimica.withValues(alpha: 0.2)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showFavoritesOnly
                    ? AppColors.expansionAlquimica
                    : AppColors.raizSagrada.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                '🤍',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Filtrar items de hipnosis según búsqueda y favoritos
  List<ContentItem> _getFilteredHypnosisItems(List<ContentItem> items) {
    var filtered = items;
    
    // Excluir tappings - solo mostrar hipnosis
    filtered = filtered.where((item) {
      final title = item.title.toLowerCase();
      final category = item.type?.toString().toLowerCase() ?? '';
      // Excluir si es tapping
      if (category.contains('tapping') || 
          title.contains('tapping') || 
          title.contains('tappings')) {
        return false;
      }
      return true;
    }).toList();
    
    // Filtrar por búsqueda
    final searchQuery = _hypnosisSearchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(searchQuery);
      }).toList();
    }
    
    // Filtrar por favoritos
    if (_showFavoritesOnly) {
      filtered = filtered.where((item) {
        return _favoriteIds.contains(item.id);
      }).toList();
    }
    
    return filtered;
  }

  /// Cargar favoritos
  Future<void> _loadFavorites() async {
    final favorites = await _favoritesService.getFavorites();
    setState(() {
      _favoriteIds = favorites.toSet();
    });
  }

  /// Grid de hipnosis con favoritos y descripción
  Widget _buildHypnosisGrid(List<ContentItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildHypnosisCard(item);
      },
    );
  }

  /// Card de hipnosis con descripción y favoritos
  Widget _buildHypnosisCard(ContentItem item) {
    final isFavorite = _favoriteIds.contains(item.id);
    
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen - ocupa espacio disponible
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.image != null && item.image!.isNotEmpty
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
                    // Botón de favorito
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          await _favoritesService.toggleFavorite(item.id);
                          await _loadFavorites();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            isFavorite ? '🤍' : '🤍',
                            style: TextStyle(
                              fontSize: 20,
                              color: isFavorite 
                                  ? AppColors.expansionAlquimica
                                  : AppColors.raizSagrada.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Título - tamaño fijo
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.title,
                style: AppTypography.ralewayBold(
                  fontSize: 12,
                  color: AppColors.raizSagrada,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir contenido de MEDITACIONES FÉNIX
  Widget _buildMeditationsFenixContent(ContentProvider provider) {
    final allItems = provider.meditations;
    final filteredItems = _getFilteredMeditationsItems(allItems);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text(
            'Alinéate en pocos minutos',
            style: AppTypography.kaushanTitle(
              fontSize: 24,
              color: AppColors.expansionAlquimica,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          
          // Video promocional
          _PortalesVideoPlayer(videoUrl: AppConstants.meditationsFenixVideoUrl),
          const SizedBox(height: 16),
          
          // Texto descriptivo
          Text(
            'Inicia tu día alineándote en pocos minutos.',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Buscador y filtro de favoritos
          _buildMeditationsSearchBar(),
          const SizedBox(height: 8),
          
          // Grid de meditaciones
          if (filteredItems.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _showMeditationsFavoritesOnly 
                      ? 'No tienes favoritos aún'
                      : 'No se encontraron resultados',
                  style: AppTypography.ralewayRegular(
                    fontSize: 14,
                    color: AppColors.raizSagrada.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
            _buildMeditationsGrid(filteredItems),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Buscador y filtro de favoritos para Meditaciones
  Widget _buildMeditationsSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.raizSagrada.withValues(alpha: 0.2),
              ),
            ),
            child: TextField(
              controller: _meditationsSearchController,
              decoration: InputDecoration(
                hintText: 'Buscar meditaciones...',
                hintStyle: AppTypography.ralewayRegular(
                  fontSize: 14,
                  color: AppColors.raizSagrada.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColors.raizSagrada.withValues(alpha: 0.5),
                ),
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
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            setState(() {
              _showMeditationsFavoritesOnly = !_showMeditationsFavoritesOnly;
            });
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _showMeditationsFavoritesOnly 
                  ? AppColors.expansionAlquimica.withValues(alpha: 0.2)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _showMeditationsFavoritesOnly
                    ? AppColors.expansionAlquimica
                    : AppColors.raizSagrada.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                '🤍',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Filtrar items de meditaciones según búsqueda y favoritos
  List<ContentItem> _getFilteredMeditationsItems(List<ContentItem> items) {
    var filtered = items;
    
    // Filtrar por búsqueda
    final searchQuery = _meditationsSearchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        return item.title.toLowerCase().contains(searchQuery);
      }).toList();
    }
    
    // Filtrar por favoritos
    if (_showMeditationsFavoritesOnly) {
      filtered = filtered.where((item) {
        return _favoriteIds.contains(item.id);
      }).toList();
    }
    
    return filtered;
  }

  /// Grid de meditaciones con favoritos
  Widget _buildMeditationsGrid(List<ContentItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildMeditationCard(item);
      },
    );
  }

  /// Card de meditación con favoritos
  Widget _buildMeditationCard(ContentItem item) {
    final isFavorite = _favoriteIds.contains(item.id);
    
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen - ocupa espacio disponible
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    item.image != null && item.image!.isNotEmpty
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
                    // Botón de favorito
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          await _favoritesService.toggleFavorite(item.id);
                          await _loadFavorites();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            isFavorite ? '🤍' : '🤍',
                            style: TextStyle(
                              fontSize: 20,
                              color: isFavorite 
                                  ? AppColors.expansionAlquimica
                                  : AppColors.raizSagrada.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Título - tamaño fijo
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                item.title,
                style: AppTypography.ralewayBold(
                  fontSize: 12,
                  color: AppColors.raizSagrada,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lista de documentos disponibles
  Widget _buildDocumentsList() {
    final documents = _getAvailableDocuments();
    
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...documents.map((doc) => _buildDocumentCard(doc)),
      ],
    );
  }

  /// Obtener documentos disponibles (PDFs de Google Docs)
  List<Map<String, dynamic>> _getAvailableDocuments() {
    return [
      {
        'id': '1',
        'titulo': 'Mensajes del universo',
        'descripcion': 'Descubre los mensajes que hay para ti detrás de los números, animales, símbolos y más',
        'url': 'https://docs.google.com/document/d/1uwVoByqcPKx0opMIjcrGHeNn0srdkRMqM0zUFaTB1uk/export?format=pdf',
      },
      {
        'id': '2',
        'titulo': 'Astrología',
        'descripcion': 'Descubre la energía de la luna y fases astrológicas para usar a tu favor',
        'url': 'https://docs.google.com/document/d/17v6dCfngpZrXbetMxq1reIx484I1YSxlxoOlzNla3Do/export?format=pdf',
      },
      {
        'id': '3',
        'titulo': 'Emociones',
        'descripcion': 'Descubre el mensaje detrás de tus emociones y recuerda quién eres',
        'url': 'https://docs.google.com/document/d/1faEEBh0NAdK4ASKzOlTCGq6vQBlR4xIjNXn-GxkYD60/export?format=pdf',
      },
    ];
  }

  /// Construir card de documento
  Widget _buildDocumentCard(Map<String, dynamic> document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.raizSagrada.withValues(alpha: 0.1),
        ),
      ),
      child: InkWell(
        onTap: () => _openDocument(document),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.expansionAlquimica.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppColors.expansionAlquimica,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document['titulo'] as String,
                      style: AppTypography.ralewayBold(
                        fontSize: 16,
                        color: AppColors.raizSagrada,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document['descripcion'] as String,
                      style: AppTypography.ralewayRegular(
                        fontSize: 12,
                        color: AppColors.raizSagrada.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.raizSagrada.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Abrir documento
  void _openDocument(Map<String, dynamic> document) {
    // Abrir visor nativo de documento
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _DocumentViewer(
          document: document,
        ),
      ),
    );
  }

  /// Abrir WhatsApp para Apoyo Fénix
  Future<void> _openWhatsAppApoyo() async {
    try {
      final message = Uri.encodeComponent('¡Hola! Me gustaría obtener más información.\n¡Gracias!👋');
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

  /// Obtener Tappings del contenido del usuario
  List<ContentItem> _getTappings(ContentProvider provider) {
    return provider.all.where((item) {
      final category = (item.category ?? '').toLowerCase();
      final title = item.title.toLowerCase();
      return category.contains('tapping') || 
             category.contains('tappings') ||
             title.contains('tapping') ||
             title.contains('tappings');
    }).toList();
  }

  /// Construir contenido de TAPPINGS
  Widget _buildTappingsContent() {
    final provider = context.watch<ContentProvider>();
    final authProvider = context.watch<AuthProvider>();
    final tappings = _getTappings(provider);
    final isLoading = provider.isLoading;

    // Cargar contenido del usuario si no está cargado
    if (!isLoading && provider.content == null && authProvider.user?.email != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.loadUserContent(authProvider.user!.email!);
      });
    }

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: CircularProgressIndicator(
            color: AppColors.ascenso,
          ),
        ),
      );
    }

    if (tappings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 64,
                color: AppColors.raizSagrada.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No tienes Tappings disponibles',
                style: AppTypography.ralewayRegular(
                  fontSize: 16,
                  color: AppColors.raizSagrada.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tappings.length,
        itemBuilder: (context, index) {
          final tapping = tappings[index];
          return _buildTappingCard(tapping);
        },
      ),
    );
  }

  /// Construir card de Tapping individual
  Widget _buildTappingCard(ContentItem tapping) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.raizSagrada.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen destacada (si existe)
          if (tapping.image != null && tapping.image!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: tapping.image!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: AppColors.raizSagrada.withValues(alpha: 0.1),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.ascenso,
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  color: AppColors.raizSagrada.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.video_library_outlined,
                    size: 48,
                    color: AppColors.raizSagrada.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título
                Text(
                  tapping.title,
                  style: AppTypography.ralewayBold(
                    fontSize: 18,
                    color: AppColors.raizSagrada,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Descripción (si existe)
                if (tapping.description != null && tapping.description!.isNotEmpty)
                  Text(
                    _cleanDescription(tapping.description!),
                    style: AppTypography.ralewayRegular(
                      fontSize: 14,
                      color: AppColors.raizSagrada.withValues(alpha: 0.8),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 16),
                
                // Reproductor de video
                if (tapping.downloadUrl != null && tapping.downloadUrl!.isNotEmpty)
                  _TappingVideoPlayer(
                    videoUrl: tapping.downloadUrl!,
                    title: tapping.title,
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.raizSagrada.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: AppColors.raizSagrada.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Video no disponible',
                            style: AppTypography.ralewayRegular(
                              fontSize: 14,
                              color: AppColors.raizSagrada.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para reproducir video de Tapping (URL directa o YouTube)
class _TappingVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String title;

  const _TappingVideoPlayer({
    required this.videoUrl,
    required this.title,
  });

  @override
  State<_TappingVideoPlayer> createState() => _TappingVideoPlayerState();
}

class _TappingVideoPlayerState extends State<_TappingVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Verificar si es URL de YouTube
      final youtubeMatch = RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]+)').firstMatch(widget.videoUrl);
      
      if (youtubeMatch != null) {
        // Es YouTube - usar YoutubeExplode
        final videoId = youtubeMatch.group(1)!;
        final yt = YoutubeExplode();
        final manifest = await yt.videos.streams.getManifest(videoId);
        
        VideoStreamInfo? streamInfo;
        if (manifest.muxed.isNotEmpty) {
          streamInfo = manifest.muxed.last;
        } else if (manifest.videoOnly.isNotEmpty) {
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
        
        _controller = VideoPlayerController.networkUrl(streamInfo.url);
        yt.close();
      } else {
        // Es URL directa de video
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      }

      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        showControls: true,
        allowFullScreen: false,
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

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error cargando video de Tapping: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
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

/// Widget para reproducir video de Vimeo de forma nativa (PORTALES)
class _PortalesVideoPlayer extends StatefulWidget {
  final String videoUrl;

  const _PortalesVideoPlayer({required this.videoUrl});

  @override
  State<_PortalesVideoPlayer> createState() => _PortalesVideoPlayerState();
}

class _PortalesVideoPlayerState extends State<_PortalesVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Extraer ID de Vimeo de la URL
      final vimeoMatch = RegExp(r'vimeo\.com/(\d+)').firstMatch(widget.videoUrl);
      if (vimeoMatch == null) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      final videoId = vimeoMatch.group(1)!;
      
      // Obtener URL directa usando API de Vimeo
      final vimeoService = VimeoService();
      final directUrl = await vimeoService.getVimeoVideoUrl(videoId);
      
      if (directUrl == null || directUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
        return;
      }

      // Crear controlador de video con la URL directa
      _controller = VideoPlayerController.networkUrl(Uri.parse(directUrl));

      await _controller!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: false,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        showControls: true,
        allowFullScreen: false,
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

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error cargando video de Vimeo: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
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

/// Visor de documentos PDF nativo con navegación entre páginas
class _DocumentViewer extends StatefulWidget {
  final Map<String, dynamic> document;

  const _DocumentViewer({required this.document});

  @override
  State<_DocumentViewer> createState() => _DocumentViewerState();
}

class _DocumentViewerState extends State<_DocumentViewer> {
  bool _isLoading = true;
  String? _error;
  Uint8List? _pdfBytes;
  
  // Controlador del PDF viewer
  late PdfViewerController _pdfController;
  
  // Estado de navegación
  int _currentPage = 1;
  int _totalPages = 0;
  double _currentZoom = 1.0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
    _enableScreenshotProtection();
    _loadDocument();
  }

  @override
  void dispose() {
    _disableScreenshotProtection();
    _pdfController.dispose();
    super.dispose();
  }
  
  /// Activar protección contra capturas de pantalla
  Future<void> _enableScreenshotProtection() async {
    try {
      await FlutterScreenshotBlocker.enableScreenshotBlocking();
      debugPrint('🔒 Protección de capturas activada');
    } catch (e) {
      debugPrint('⚠️ No se pudo activar protección de capturas: $e');
    }
  }
  
  /// Desactivar protección contra capturas de pantalla
  Future<void> _disableScreenshotProtection() async {
    try {
      await FlutterScreenshotBlocker.disableScreenshotBlocking();
      debugPrint('🔓 Protección de capturas desactivada');
    } catch (e) {
      debugPrint('⚠️ No se pudo desactivar protección de capturas: $e');
    }
  }

  Future<void> _loadDocument() async {
    try {
      final url = widget.document['url'] as String;
      
      // Cargar PDF
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _pdfBytes = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar el documento (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando documento: $e');
      setState(() {
        _error = 'Error al cargar el documento. Verifica tu conexión.';
        _isLoading = false;
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _pdfController.jumpToPage(page);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfController.nextPage();
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfController.previousPage();
    }
  }

  void _zoomIn() {
    final newZoom = (_currentZoom + 0.25).clamp(0.5, 3.0);
    _pdfController.zoomLevel = newZoom;
  }

  void _zoomOut() {
    final newZoom = (_currentZoom - 0.25).clamp(0.5, 3.0);
    _pdfController.zoomLevel = newZoom;
  }

  void _showPageSelector() {
    showDialog(
      context: context,
      builder: (context) => _PageSelectorDialog(
        currentPage: _currentPage,
        totalPages: _totalPages,
        onPageSelected: _goToPage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.origen,
      appBar: AppBar(
        backgroundColor: AppColors.raizSagrada,
        title: Text(
          widget.document['titulo'] as String,
          style: AppTypography.kaushanTitle(
            fontSize: 20,
            color: AppColors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
        actions: _pdfBytes != null ? [
          IconButton(
            icon: const Icon(Icons.zoom_out, color: AppColors.white),
            onPressed: _zoomOut,
            tooltip: 'Alejar',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: AppColors.white),
            onPressed: _zoomIn,
            tooltip: 'Acercar',
          ),
        ] : null,
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _pdfBytes != null
                  ? _buildPdfViewer()
                  : const SizedBox.shrink(),
      bottomNavigationBar: _pdfBytes != null && !_isLoading && _error == null
          ? _buildNavigationBar()
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.ascenso),
          const SizedBox(height: 16),
          Text(
            'Cargando documento...',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 56,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: AppTypography.ralewayRegular(
                fontSize: 16,
                color: AppColors.raizSagrada,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _error = null;
                });
                _loadDocument();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ascenso,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer() {
    return SfPdfViewer.memory(
      _pdfBytes!,
      controller: _pdfController,
      enableDoubleTapZooming: true,
      enableTextSelection: false,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      pageLayoutMode: PdfPageLayoutMode.single,
      scrollDirection: PdfScrollDirection.horizontal,
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        setState(() {
          _totalPages = details.document.pages.count;
        });
      },
      onPageChanged: (PdfPageChangedDetails details) {
        setState(() {
          _currentPage = details.newPageNumber;
        });
      },
      onZoomLevelChanged: (PdfZoomDetails details) {
        setState(() {
          _currentZoom = details.newZoomLevel;
        });
      },
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.raizSagrada.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón página anterior
          IconButton(
            onPressed: _currentPage > 1 ? _previousPage : null,
            icon: Icon(
              Icons.chevron_left,
              color: _currentPage > 1 
                  ? AppColors.raizSagrada 
                  : AppColors.raizSagrada.withValues(alpha: 0.3),
              size: 32,
            ),
            tooltip: 'Página anterior',
          ),
          
          // Indicador de página (tocable para ir a página específica)
          GestureDetector(
            onTap: _totalPages > 1 ? _showPageSelector : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.expansionAlquimica.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_currentPage / $_totalPages',
                    style: AppTypography.ralewayBold(
                      fontSize: 16,
                      color: AppColors.raizSagrada,
                    ),
                  ),
                  if (_totalPages > 1) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.unfold_more,
                      size: 18,
                      color: AppColors.raizSagrada.withValues(alpha: 0.7),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Botón página siguiente
          IconButton(
            onPressed: _currentPage < _totalPages ? _nextPage : null,
            icon: Icon(
              Icons.chevron_right,
              color: _currentPage < _totalPages 
                  ? AppColors.raizSagrada 
                  : AppColors.raizSagrada.withValues(alpha: 0.3),
              size: 32,
            ),
            tooltip: 'Página siguiente',
          ),
        ],
      ),
    );
  }
}

/// Diálogo para seleccionar página específica
class _PageSelectorDialog extends StatefulWidget {
  final int currentPage;
  final int totalPages;
  final Function(int) onPageSelected;

  const _PageSelectorDialog({
    required this.currentPage,
    required this.totalPages,
    required this.onPageSelected,
  });

  @override
  State<_PageSelectorDialog> createState() => _PageSelectorDialogState();
}

class _PageSelectorDialogState extends State<_PageSelectorDialog> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage() {
    final page = int.tryParse(_controller.text);
    if (page == null || page < 1 || page > widget.totalPages) {
      setState(() {
        _errorText = 'Ingresa un número entre 1 y ${widget.totalPages}';
      });
      return;
    }
    Navigator.of(context).pop();
    widget.onPageSelected(page);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Ir a página',
        style: AppTypography.ralewayBold(
          fontSize: 18,
          color: AppColors.raizSagrada,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: '1 - ${widget.totalPages}',
              errorText: _errorText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.ascenso, width: 2),
              ),
            ),
            onSubmitted: (_) => _goToPage(),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Total: ${widget.totalPages} páginas',
            style: AppTypography.ralewayRegular(
              fontSize: 12,
              color: AppColors.raizSagrada.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancelar',
            style: AppTypography.ralewayRegular(
              fontSize: 14,
              color: AppColors.raizSagrada.withValues(alpha: 0.7),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _goToPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ascenso,
            foregroundColor: AppColors.white,
          ),
          child: const Text('Ir'),
        ),
      ],
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
