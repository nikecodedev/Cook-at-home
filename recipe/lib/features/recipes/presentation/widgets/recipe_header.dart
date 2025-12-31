import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import '../../../../models/recipe_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Modern recipe header with image banner, title, description, and info chips
class RecipeHeader extends StatelessWidget {
  final Recipe recipe;
  final bool isTablet;

  const RecipeHeader({
    super.key,
    required this.recipe,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Banner
        Container(
          width: double.infinity,
          height: isTablet ? 380 : 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.secondary.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty)
              ? _RecipeImageWithRetry(
                  imageUrl: recipe.imageUrl!,
                  height: isTablet ? 380 : 280,
                  placeholder: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFF7F7F7),
                          const Color(0xFFEDEDED),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 80,
                      color: Color(0xFFBDBDBD),
                    ),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF7F7F7),
                        const Color(0xFFEDEDED),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu_rounded,
                    size: 80,
                    color: Color(0xFFBDBDBD),
                  ),
                ),
        ),

        const SizedBox(height: 32),

        // Title
        Text(
          recipe.title,
          style: TextStyle(
            fontSize: isTablet ? 36 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212121),
            letterSpacing: -0.8,
            height: 1.3,
          ),
        ),

        const SizedBox(height: 12),

        // Description (if available) - using source as description placeholder
        if (recipe.source != null && recipe.source!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              recipe.source!,
              style: TextStyle(
                fontSize: isTablet ? 16 : 15,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF757575),
                height: 1.5,
                letterSpacing: -0.2,
              ),
            ),
          ),

      ],
    );
  }
}

/// Image widget with retry logic for recipe images
class _RecipeImageWithRetry extends StatefulWidget {
  final String imageUrl;
  final double height;
  final Widget placeholder;

  const _RecipeImageWithRetry({
    required this.imageUrl,
    required this.height,
    required this.placeholder,
  });

  @override
  State<_RecipeImageWithRetry> createState() => _RecipeImageWithRetryState();
}

class _RecipeImageWithRetryState extends State<_RecipeImageWithRetry> {
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
        color: const Color(0xFFF7F7F7),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF757575)),
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
            color: const Color(0xFFF7F7F7),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF757575)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Cargando imagen...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF757575),
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

