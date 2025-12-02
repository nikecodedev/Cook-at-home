import 'package:flutter/material.dart';

/// Modern feature card with icon, text, and micro-interactions
class ModernFeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final int index;
  final bool isTablet;
  final bool isMobile;

  const ModernFeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.index,
    required this.isTablet,
    this.isMobile = false,
  });

  @override
  State<ModernFeatureCard> createState() => _ModernFeatureCardState();
}

class _ModernFeatureCardState extends State<ModernFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.index * 0.2,
          0.6 + (widget.index * 0.2),
          curve: Curves.easeOut,
        ),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
    final scale = _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return AnimatedOpacity(
          opacity: _fadeAnimation.value,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _controller.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _controller.reverse();
            },
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: EdgeInsets.all(
                    widget.isTablet ? 36 : (widget.isMobile ? 20 : 28),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFEDEDED),
                      width: 1,
                    ),
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: widget.isTablet ? 56 : (widget.isMobile ? 44 : 48),
                        height: widget.isTablet ? 56 : (widget.isMobile ? 44 : 48),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F8F8),
                          borderRadius: BorderRadius.circular(widget.isMobile ? 14 : 16),
                        ),
                        child: Icon(
                          widget.icon,
                          size: widget.isTablet ? 28 : (widget.isMobile ? 22 : 24),
                          color: const Color(0xFFDC143C),
                        ),
                      ),

                      SizedBox(height: widget.isMobile ? 16 : 20),

                      // Title
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: widget.isTablet ? 20 : (widget.isMobile ? 16 : 18),
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF212121),
                          letterSpacing: -0.5,
                        ),
                      ),

                      SizedBox(height: widget.isMobile ? 6 : 8),

                      // Description
                      Text(
                        widget.description,
                        style: TextStyle(
                          fontSize: widget.isTablet ? 15 : (widget.isMobile ? 13 : 14),
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF757575),
                          height: 1.5,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

