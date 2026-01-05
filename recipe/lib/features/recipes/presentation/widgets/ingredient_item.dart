import 'package:flutter/material.dart';
import '../../../../models/recipe_model.dart';
import '../../../../core/utils/translations.dart';
import '../../../../core/widgets/smart_purchase_button.dart';

/// Elegant ingredient item with animations
class IngredientItem extends StatefulWidget {
  final RecipeIngredient ingredient;
  final int index;
  final bool isTablet;

  /// Callback when purchase links are updated
  final void Function(String? amazonUrl, String? walmartUrl)? onLinksUpdated;

  const IngredientItem({
    super.key,
    required this.ingredient,
    required this.index,
    required this.isTablet,
    this.onLinksUpdated,
  });

  @override
  State<IngredientItem> createState() => _IngredientItemState();
}

class _IngredientItemState extends State<IngredientItem>
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
          widget.index * 0.1,
          0.5 + (widget.index * 0.1),
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
          widget.index * 0.1,
          0.5 + (widget.index * 0.1),
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
              margin: const EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(widget.isTablet ? 24 : 20),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Ingredient Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.ingredient.name,
                              style: TextStyle(
                                fontSize: widget.isTablet ? 18 : 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF212121),
                                letterSpacing: -0.3,
                              ),
                              textAlign: TextAlign.left,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F7F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${widget.ingredient.quantity} ${Translations.translateUnit(widget.ingredient.unit)}',
                                style: TextStyle(
                                  fontSize: widget.isTablet ? 13 : 12,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF757575),
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // Purchase Buttons - Smart flow with options
                  if (widget.ingredient.name.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SmartPurchaseButton(
                      itemName: widget.ingredient.name,
                      amazonLink: widget.ingredient.amazonLink,
                      walmartLink: widget.ingredient.walmartLink,
                      size: SmartPurchaseButtonSize.small,
                      onLinksUpdated: widget.onLinksUpdated,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

