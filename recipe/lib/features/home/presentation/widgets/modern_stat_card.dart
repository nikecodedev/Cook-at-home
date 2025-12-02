import 'package:flutter/material.dart';

/// Modern minimal stat card with Notion-style design
class ModernStatCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final bool isTablet;

  const ModernStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.onTap,
    required this.isTablet,
  });

  @override
  State<ModernStatCard> createState() => _ModernStatCardState();
}

class _ModernStatCardState extends State<ModernStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
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
    final scale = _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0);

    return GestureDetector(
      onTapDown: widget.onTap != null ? (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      } : null,
      onTapUp: widget.onTap != null ? (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onTap?.call();
      } : null,
      onTapCancel: widget.onTap != null ? () {
        setState(() => _isPressed = false);
        _controller.reverse();
      } : null,
      child: MouseRegion(
        onEnter: widget.onTap != null ? (_) => setState(() => _isHovered = true) : null,
        onExit: widget.onTap != null ? (_) => setState(() => _isHovered = false) : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                padding: EdgeInsets.all(widget.isTablet ? 28 : 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(24),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon
                    Container(
                      width: widget.isTablet ? 56 : 48,
                      height: widget.isTablet ? 56 : 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        widget.icon,
                        size: widget.isTablet ? 28 : 24,
                        color: widget.iconColor,
                      ),
                    ),

                    const Spacer(),

                    // Value
                    Text(
                      widget.value,
                      style: TextStyle(
                        fontSize: widget.isTablet ? 36 : 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF212121),
                        letterSpacing: -1.0,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Title
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: widget.isTablet ? 16 : 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF757575),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}



