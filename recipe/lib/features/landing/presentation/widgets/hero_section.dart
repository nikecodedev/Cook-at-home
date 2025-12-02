import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';

/// Hero section with headline, subheadline, CTAs, and illustration placeholder
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 768;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 48 : 24,
        vertical: isTablet ? 80 : 60,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration Placeholder
          Container(
            width: isTablet ? 200 : 150,
            height: isTablet ? 200 : 150,
            margin: const EdgeInsets.only(bottom: 48),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F7F7),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFFEDEDED),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              size: 80,
              color: Color(0xFFBDBDBD),
            ),
          ),

          // Bold Headline
          Text(
            'Cook Smarter,\nNot Harder',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 56 : isMobile ? 36 : 48,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF212121),
              height: 1.1,
              letterSpacing: -1.5,
            ),
          ),

          const SizedBox(height: 24),

          // Soft Subheadline
          Text(
            'Transform your kitchen into a culinary haven with smart recipe management, pantry tracking, and personalized meal suggestions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isTablet ? 20 : 16,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF757575),
              height: 1.6,
              letterSpacing: -0.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 48),

          // CTA Buttons
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              // Primary Filled Button
              _PrimaryCTAButton(
                text: 'Get Started',
                onPressed: () => context.push(Routes.register),
              ),

              // Secondary Outlined Button
              _SecondaryCTAButton(
                text: 'View Demo',
                onPressed: () {
                  // Handle demo action
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Primary filled CTA button
class _PrimaryCTAButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _PrimaryCTAButton({
    required this.text,
    required this.onPressed,
  });

  @override
  State<_PrimaryCTAButton> createState() => _PrimaryCTAButtonState();
}

class _PrimaryCTAButtonState extends State<_PrimaryCTAButton>
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF212121),
                borderRadius: BorderRadius.circular(24),
                boxShadow: _isPressed
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Secondary outlined CTA button
class _SecondaryCTAButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;

  const _SecondaryCTAButton({
    required this.text,
    required this.onPressed,
  });

  @override
  State<_SecondaryCTAButton> createState() => _SecondaryCTAButtonState();
}

class _SecondaryCTAButtonState extends State<_SecondaryCTAButton>
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFEDEDED),
                  width: 1.5,
                ),
              ),
              child: Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                  letterSpacing: -0.3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}



