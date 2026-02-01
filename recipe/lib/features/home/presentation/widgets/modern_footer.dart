import 'package:flutter/material.dart';

/// Pie de página minimalista con enlaces
class ModernFooter extends StatelessWidget {
  const ModernFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : (isMobile ? 16 : 24),
        vertical: isTablet ? 40 : (isMobile ? 24 : 32),
      ),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFFEDEDED),
            width: 1,
          ),
        ),
      ),
      child: Wrap(
        spacing: isTablet ? 32 : (isMobile ? 16 : 24),
        runSpacing: isMobile ? 12 : 16,
        alignment: WrapAlignment.center,
        children: [
          _FooterLink(text: 'Acerca de', onTap: () {}),
          _FooterLink(text: 'Política de Privacidad', onTap: () {}),
          _FooterLink(text: 'Términos', onTap: () {}),
          _FooterLink(text: 'Contacto', onTap: () {}),
        ],
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _FooterLink({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFFA8B0C1),
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

