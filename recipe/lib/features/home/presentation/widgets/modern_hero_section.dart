import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

/// Sección hero moderna con título, subtexto, botones e ilustración
class ModernHeroSection extends StatefulWidget {
  const ModernHeroSection({super.key});

  @override
  State<ModernHeroSection> createState() => _ModernHeroSectionState();
}

class _ModernHeroSectionState extends State<ModernHeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth < 600;
    final isSmallMobile = screenWidth < 400;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 48 : (isMobile ? 16 : 24),
                vertical: isTablet ? 100 : (isMobile ? 48 : 80),
              ),
              child: isTablet
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildContent(context, isTablet, false),
                        ),
                        const SizedBox(width: 48),
                        Expanded(
                          child: _buildIllustration(isTablet, false),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildContent(context, isTablet, isMobile),
                        SizedBox(height: isMobile ? 32 : 40),
                        _buildIllustration(isTablet, isMobile),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, bool isTablet, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Text(
          'Cocina Más Inteligente Con\nLo Que Ya Tienes.',
          style: TextStyle(
            fontSize: isTablet ? 48 : (isMobile ? 28 : 36),
            fontWeight: FontWeight.bold,
            color: const Color(0xFF212121),
            height: 1.2,
            letterSpacing: isMobile ? -1.0 : -1.5,
          ),
        ),

        SizedBox(height: isMobile ? 16 : 24),

        // Subtexto
        Text(
          'Descubre recetas basadas en tus ingredientes y ahorra dinero al instante.',
          style: TextStyle(
            fontSize: isTablet ? 20 : (isMobile ? 14 : 16),
            fontWeight: FontWeight.w400,
            color: const Color(0xFF757575),
            height: 1.6,
            letterSpacing: -0.3,
          ),
        ),

        SizedBox(height: isMobile ? 32 : 40),

        // Botones
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PrimaryButton(
                    text: 'Comenzar',
                    onPressed: () => context.push(Routes.register),
                    isTablet: isTablet,
                    isMobile: isMobile,
                  ),
                  const SizedBox(height: 12),
                  _SecondaryButton(
                    text: 'Explorar Recetas',
                    onPressed: () => context.push(Routes.recipes),
                    isTablet: isTablet,
                    isMobile: isMobile,
                  ),
                ],
              )
            : Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _PrimaryButton(
                    text: 'Comenzar',
                    onPressed: () => context.push(Routes.register),
                    isTablet: isTablet,
                    isMobile: isMobile,
                  ),
                  _SecondaryButton(
                    text: 'Explorar Recetas',
                    onPressed: () => context.push(Routes.recipes),
                    isTablet: isTablet,
                    isMobile: isMobile,
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildIllustration(bool isTablet, bool isMobile) {
    return Container(
      height: isTablet ? 450 : (isMobile ? 240 : 320),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFDC143C).withOpacity(0.08),
            const Color(0xFFDC143C).withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFDC143C).withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.restaurant_menu_rounded,
        size: isTablet ? 140 : (isMobile ? 80 : 100),
        color: const Color(0xFFDC143C).withOpacity(0.4),
      ),
    );
  }
}

/// Botón principal con animación de escala
class _PrimaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isTablet;
  final bool isMobile;

  const _PrimaryButton({
    required this.text,
    required this.onPressed,
    required this.isTablet,
    this.isMobile = false,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isTablet ? 32 : 28,
                vertical: widget.isTablet ? 18 : 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFDC143C),
                borderRadius: BorderRadius.circular(24),
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFFDC143C).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.isTablet ? 16 : (widget.isMobile ? 14 : 15),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
                textAlign: widget.isMobile ? TextAlign.center : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Botón secundario con borde y animación de escala
class _SecondaryButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isTablet;
  final bool isMobile;

  const _SecondaryButton({
    required this.text,
    required this.onPressed,
    required this.isTablet,
    this.isMobile = false,
  });

  @override
  State<_SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<_SecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: widget.isTablet ? 32 : (widget.isMobile ? 24 : 28),
                vertical: widget.isTablet ? 18 : (widget.isMobile ? 16 : 16),
              ),
              width: widget.isMobile ? double.infinity : null,
              alignment: widget.isMobile ? Alignment.center : null,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFDC143C).withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                widget.text,
                style: TextStyle(
                  fontSize: widget.isTablet ? 16 : (widget.isMobile ? 14 : 15),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC143C),
                  letterSpacing: -0.3,
                ),
                textAlign: widget.isMobile ? TextAlign.center : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

