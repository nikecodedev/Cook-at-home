import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
          child: recipe.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: recipe.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: const Color(0xFFF7F7F7),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF757575)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: const Color(0xFFF7F7F7),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      size: 64,
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

