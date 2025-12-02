import 'package:flutter/material.dart';
import '../../../../models/recipe_model.dart';
import '../../../../core/theme/app_colors.dart';

/// Info chips row with prep time, difficulty, and servings
class InfoChipsRow extends StatelessWidget {
  final Recipe recipe;
  final bool isTablet;

  const InfoChipsRow({
    super.key,
    required this.recipe,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InfoChip(
            icon: Icons.timer_outlined,
            label: 'Tiempo',
            value: recipe.formattedCookTime,
            isTablet: isTablet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoChip(
            icon: Icons.people_outline_rounded,
            label: 'Porciones',
            value: '4', // Default servings, can be added to Recipe model
            isTablet: isTablet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _InfoChip(
            icon: Icons.restaurant_menu_rounded,
            label: 'Ingredientes',
            value: '${recipe.ingredients.length}',
            isTablet: isTablet,
          ),
        ),
      ],
    );
  }
}

/// Individual info chip widget
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isTablet;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8E8E8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.1),
                  AppColors.secondary.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: isTablet ? 20 : 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF212121),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 12 : 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF757575),
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
