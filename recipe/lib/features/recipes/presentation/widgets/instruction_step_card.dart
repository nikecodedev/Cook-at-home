import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Numbered instruction step card with smooth animations
class InstructionStepCard extends StatefulWidget {
  final String instruction;
  final int stepNumber;
  final bool isTablet;

  const InstructionStepCard({
    super.key,
    required this.instruction,
    required this.stepNumber,
    required this.isTablet,
  });

  @override
  State<InstructionStepCard> createState() => _InstructionStepCardState();
}

class _InstructionStepCardState extends State<InstructionStepCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.stepNumber * 0.1,
          0.5 + (widget.stepNumber * 0.1),
          curve: Curves.easeOut,
        ),
      ),
    );

    _slideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.stepNumber * 0.1,
          0.5 + (widget.stepNumber * 0.1),
          curve: Curves.easeOutCubic,
        ),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return AnimatedOpacity(
          opacity: _fadeAnimation.value,
          duration: const Duration(milliseconds: 200),
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.all(widget.isTablet ? 28 : 24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(18),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Number Badge
                  Container(
                    width: widget.isTablet ? 48 : 44,
                    height: widget.isTablet ? 48 : 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          AppColors.primary.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.stepNumber}',
                        style: TextStyle(
                          fontSize: widget.isTablet ? 20 : 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Instruction Text
                  Expanded(
                    child: Text(
                      widget.instruction,
                      style: TextStyle(
                        fontSize: widget.isTablet ? 17 : 16,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF212121),
                        height: 1.7,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

