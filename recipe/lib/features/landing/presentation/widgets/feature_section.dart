import 'package:flutter/material.dart';
import 'feature_card.dart';

/// Sección de características con tres tarjetas estéticas
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
        'title': 'Gestión Inteligente de Despensa',
        'description':
            'Mantén el control de tus ingredientes sin esfuerzo. Sabe qué tienes, qué necesitas y cuándo caducan los productos.',
      },
      {
        'icon': Icons.restaurant_menu_rounded,
        'title': 'Recomendaciones de Recetas',
        'description':
            'Obtén sugerencias de recetas personalizadas basadas en los ingredientes de tu despensa. Cocina más inteligente con planificación de comidas.',
      },
      {
        'icon': Icons.shopping_cart_rounded,
        'title': 'Listas de Compras Inteligentes',
        'description':
            'Genera listas de compras desde recetas automáticamente. Nunca olvides un ingrediente con gestión inteligente de listas.',
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
          // Título de Sección
          Text(
            'Todo lo que necesitas',
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



