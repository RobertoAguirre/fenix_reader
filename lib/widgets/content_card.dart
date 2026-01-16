import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

/// Card de contenido para listas (biblioteca)
class ContentListItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;

  const ContentListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
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
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _PlaceholderBox(),
                        errorWidget: (context, url, error) => _PlaceholderBox(),
                      )
                    : _PlaceholderBox(),
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
            // Favorito
            GestureDetector(
              onTap: onFavoriteTap,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.ascenso : AppColors.raizSagrada.withValues(alpha: 0.25),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card grande para contenido destacado
class ContentFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String? buttonText;
  final bool showBadge;
  final String? badgeText;
  final VoidCallback? onTap;

  const ContentFeatureCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.buttonText,
    this.showBadge = false,
    this.badgeText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _PlaceholderBox(),
                        errorWidget: (context, url, error) => _PlaceholderBox(),
                      )
                    : _PlaceholderBox(),
              ),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.ralewayBold(fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.ralewayLight(fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (buttonText != null || showBadge) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (buttonText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ascenso,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              buttonText!,
                              style: AppTypography.ralewayBold(
                                fontSize: 12,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        const Spacer(),
                        if (showBadge && badgeText != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ascenso,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              badgeText!,
                              style: AppTypography.ralewayBold(
                                fontSize: 10,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.raizSagrada.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.raizSagrada.withValues(alpha: 0.4),
          size: 24,
        ),
      ),
    );
  }
}

