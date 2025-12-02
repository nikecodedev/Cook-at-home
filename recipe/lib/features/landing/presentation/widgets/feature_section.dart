import 'package:flutter/material.dart';
import 'feature_card.dart';

/// Features section with three aesthetic cards
class FeatureSection extends StatelessWidget {
  const FeatureSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth < 600;

    final features = [
      {
        'icon': Icons.kitchen_rounded,
        'title': 'Smart Pantry Management',
        'description':
            'Keep track of your ingredients effortlessly. Know what you have, what you need, and when items expire.',
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'Recipe Recommendations',
        'description':
            'Get personalized recipe suggestions based on your pantry items. Cook smarter with AI-powered meal planning.',
      },
      {
        'icon': Icons.shopping_cart_rounded,
        'title': 'Intelligent Shopping Lists',
        'description':
            'Generate shopping lists from recipes automatically. Never forget an ingredient again with smart list management.',
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : 24,
        vertical: isTablet ? 80 : 60,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            'Everything you need',
            style: TextStyle(
              fontSize: isTablet ? 40 : isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
              letterSpacing: -1.0,
            ),
          ),

          const SizedBox(height: 48),

          // Feature Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              if (isTablet) {
                // Tablet: 3 columns
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: features.asMap().entries.map((entry) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: entry.key < features.length - 1 ? 24 : 0,
                        ),
                        child: FeatureCard(
                          icon: entry.value['icon'] as IconData,
                          title: entry.value['title'] as String,
                          description: entry.value['description'] as String,
                          index: entry.key,
                        ),
                      ),
                    );
                  }).toList(),
                );
              } else {
                // Mobile: Single column
                return Column(
                  children: features.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: FeatureCard(
                        icon: entry.value['icon'] as IconData,
                        title: entry.value['title'] as String,
                        description: entry.value['description'] as String,
                        index: entry.key,
                      ),
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}



