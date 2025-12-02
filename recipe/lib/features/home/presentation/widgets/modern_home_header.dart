import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

/// Modern minimalist header with logo, search, and profile
class ModernHomeHeader extends StatelessWidget {
  const ModernHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : (isMobile ? 16 : 24),
        vertical: isMobile ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo + App Name
          Row(
            children: [
              Container(
                width: isTablet ? 40 : (isMobile ? 28 : 32),
                height: isTablet ? 40 : (isMobile ? 28 : 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC143C),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                ),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: isMobile ? 16 : 20,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Text(
                'PantryChef',
                style: TextStyle(
                  fontSize: isTablet ? 22 : (isMobile ? 16 : 18),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Right Actions
          Row(
            children: [
              // Search Icon
              Container(
                width: isTablet ? 44 : (isMobile ? 40 : 40),
                height: isTablet ? 44 : (isMobile ? 40 : 40),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F8F8),
                  borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.search_rounded,
                    color: const Color(0xFFDC143C),
                    size: isMobile ? 18 : 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    // Handle search
                  },
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              // Profile Avatar
              GestureDetector(
                onTap: () => context.push(Routes.profile),
                child: Container(
                  width: isTablet ? 44 : (isMobile ? 40 : 40),
                  height: isTablet ? 44 : (isMobile ? 40 : 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC143C),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC143C).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: isMobile ? 18 : 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

