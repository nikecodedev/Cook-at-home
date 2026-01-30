import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/firebase_constants.dart';
import '../models/recipe_model.dart';

/// Modern, responsive recipe card widget
class ModernRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final Widget? trailing;
  final double? aspectRatio;
  final bool showSource;
  final String? matchPercentage; // For suggested recipes
  final Color? matchColor; // For suggested recipes
  final String? costTier; // Optional cost tier (low, medium, high)

  const ModernRecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.trailing,
    this.aspectRatio,
    this.showSource = true,
    this.matchPercentage,
    this.matchColor,
    this.costTier,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final cardPadding = isTablet ? 24.0 : 20.0;
    final imageHeight = isTablet ? 280.0 : 240.0;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 0,
        vertical: isTablet ? 8 : 0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Section with Modern Design
              _buildImageSection(context, imageHeight, isTablet),
              
              // Content Section
              Padding(
                padding: EdgeInsets.all(cardPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            recipe.title,
                            style: TextStyle(
                              fontSize: isTablet ? 22 : 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                              height: 1.3,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 12),
                          trailing!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Stats Row - Modern Pills
                    _buildStatsRow(context, isTablet),
                    
                    // Cost Tier Badge
                    if (costTier != null) ...[
                      const SizedBox(height: 12),
                      _buildCostTierBadge(context, costTier!, isTablet),
                    ],
                    
                    // Match Badge (for suggested recipes)
                    if (matchPercentage != null) ...[
                      const SizedBox(height: 12),
                      _buildMatchBadge(context, matchPercentage!, matchColor),
                    ],

                    // Source (if available)
                    if (showSource && recipe.source != null) ...[
                      const SizedBox(height: 16),
                      _buildSourceChip(context, recipe.source!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context, double height, bool isTablet) {
    // Check if imageUrl exists and is not empty
    final hasImage = recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty;
    
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Stack(
        children: [
          // Image or Placeholder
          if (hasImage)
            _ImageWithRetry(
              imageUrl: recipe.imageUrl!,
              height: height,
              placeholder: _buildImagePlaceholder(height),
            )
          else
            _buildImagePlaceholder(height),

          // Gradient Overlay
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),

          // Match Badge Overlay (for suggested recipes)
          if (matchPercentage != null)
            Positioned(
              top: 16,
              right: 16,
              child: _buildFloatingMatchBadge(matchPercentage!, matchColor),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.9),
            AppColors.secondary.withOpacity(0.7),
            AppColors.primary.withOpacity(0.5),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              recipe.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, bool isTablet) {
    return Row(
      children: [
        Flexible(
          child: _buildModernChip(
            icon: Icons.timer_outlined,
            label: recipe.formattedCookTime,
            color: AppColors.primary,
            isTablet: isTablet,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _buildModernChip(
            icon: Icons.shopping_basket_outlined,
            label: '${recipe.ingredients.length} ${recipe.ingredients.length == 1 ? 'ingrediente' : 'ingredientes'}',
            color: AppColors.secondary,
            isTablet: isTablet,
          ),
        ),
        if (recipe.instructions.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(
            child: _buildModernChip(
              icon: Icons.list_alt_outlined,
              label: '${recipe.instructions.length} ${recipe.instructions.length == 1 ? 'paso' : 'pasos'}',
              color: AppColors.success,
              isTablet: isTablet,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildModernChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isTablet,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12,
        vertical: isTablet ? 10 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isTablet ? 18 : 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 13 : 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchBadge(BuildContext context, String percentage, Color? color) {
    final badgeColor = color ?? _getMatchColor(int.tryParse(percentage) ?? 0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor,
            badgeColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMatchIcon(int.tryParse(percentage) ?? 0),
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage% Coincidencia',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingMatchBadge(String percentage, Color? color) {
    final badgeColor = color ?? _getMatchColor(int.tryParse(percentage) ?? 0);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            badgeColor,
            badgeColor.withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getMatchIcon(int.tryParse(percentage) ?? 0),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            '$percentage%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostTierBadge(BuildContext context, String tier, bool isTablet) {
    final color = _getCostTierColor(tier);
    final label = _getCostTierLabel(tier);
    final icon = _getCostTierIcon(tier);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 14 : 12,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isTablet ? 16 : 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            'Costo: $label',
            style: TextStyle(
              fontSize: isTablet ? 12 : 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCostTierColor(String tier) {
    switch (tier) {
      case CostTiers.low:
        return AppColors.success;
      case CostTiers.medium:
        return AppColors.warning;
      case CostTiers.high:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _getCostTierLabel(String tier) {
    switch (tier) {
      case CostTiers.low:
        return 'Bajo';
      case CostTiers.medium:
        return 'Medio';
      case CostTiers.high:
        return 'Alto';
      default:
        return tier;
    }
  }

  IconData _getCostTierIcon(String tier) {
    switch (tier) {
      case CostTiers.low:
        return Icons.trending_down_rounded;
      case CostTiers.medium:
        return Icons.trending_flat_rounded;
      case CostTiers.high:
        return Icons.trending_up_rounded;
      default:
        return Icons.attach_money_rounded;
    }
  }

  Widget _buildSourceChip(BuildContext context, String source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gray50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.gray200,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link_rounded,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              source,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _getMatchColor(int percentage) {
    if (percentage >= 80) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  IconData _getMatchIcon(int percentage) {
    if (percentage >= 80) return Icons.check_circle_rounded;
    if (percentage >= 50) return Icons.info_rounded;
    return Icons.warning_rounded;
  }
}

/// Image widget with retry logic for better error handling
class _ImageWithRetry extends StatefulWidget {
  final String imageUrl;
  final double height;
  final Widget placeholder;

  const _ImageWithRetry({
    required this.imageUrl,
    required this.height,
    required this.placeholder,
  });

  @override
  State<_ImageWithRetry> createState() => _ImageWithRetryState();
}

class _ImageWithRetryState extends State<_ImageWithRetry> {
  int _retryCount = 0;
  static const int _maxRetries = 2;

  Future<void> _clearCacheAndRetry() async {
    if (_retryCount < _maxRetries) {
      setState(() {
        _retryCount++;
      });
      // Clear cache for this specific image
      try {
        await DefaultCacheManager().removeFile(widget.imageUrl);
      } catch (e) {
        debugPrint('Failed to clear cache: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: ValueKey('${widget.imageUrl}_retry_$_retryCount'),
      imageUrl: widget.imageUrl,
      height: widget.height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        height: widget.height,
        width: double.infinity,
        color: AppColors.gray100,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        // Log error for debugging
        debugPrint('Failed to load recipe image (attempt $_retryCount/$_maxRetries): $url, Error: $error');
        
        // Try to retry if we haven't exceeded max retries
        if (_retryCount < _maxRetries) {
          // Retry after a short delay
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _clearCacheAndRetry();
            }
          });
          // Show loading indicator while retrying
          return Container(
            height: widget.height,
            width: double.infinity,
            color: AppColors.gray100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cargando imagen...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // After max retries, show placeholder
        return widget.placeholder;
      },
      // Add fade in animation
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
      // Use memCacheWidth/Height to help with decoding
      memCacheWidth: 1920,
      memCacheHeight: 1080,
      // Add max width/height to prevent memory issues
      maxWidthDiskCache: 1920,
      maxHeightDiskCache: 1080,
    );
  }
}


