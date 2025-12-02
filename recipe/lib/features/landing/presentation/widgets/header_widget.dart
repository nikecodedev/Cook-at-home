import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

/// Modern minimal header widget with logo/title and icon button
class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 768;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : 24,
        vertical: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFEDEDED),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo/Title Section
          Row(
            children: [
              // Logo
              Image.asset(
                'logo/logococinaentucasa.png',
                width: isTablet ? 40 : 32,
                height: isTablet ? 40 : 32,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: isTablet ? 40 : 32,
                    height: isTablet ? 40 : 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F7F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.restaurant_menu_rounded,
                      color: Color(0xFF757575),
                      size: 20,
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // App Title
              Text(
                'Cocina en tu Casa',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF212121),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          
          // Right Icon Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push(Routes.login),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Color(0xFF757575),
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



