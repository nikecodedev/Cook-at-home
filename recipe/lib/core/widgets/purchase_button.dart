import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/purchase_link_service.dart';
import '../theme/app_colors.dart';

/// Reusable purchase button widget for Amazon and Walmart
/// 
/// This widget handles opening purchase links and provides consistent styling.
/// It works with both custom URLs and auto-generated search links.
class PurchaseButton extends StatelessWidget {
  /// The store name (e.g., 'Amazon' or 'Walmart')
  final String storeName;

  /// The URL to open. If null, will generate a search link using [itemName]
  final String? url;

  /// The item name to search for (used if [url] is null)
  final String? itemName;

  /// Whether this is an Amazon button
  final bool isAmazon;

  /// Whether this is a Walmart button
  final bool isWalmart;

  /// Custom icon to use (defaults to store-specific icons)
  final IconData? icon;

  /// Custom color to use (defaults to store-specific colors)
  final Color? color;

  /// Button size
  final PurchaseButtonSize size;

  /// Whether to show the store name text
  final bool showLabel;

  /// Whether to show "Add purchase link" instead of store name when no URL exists
  final bool showAddLinkWhenEmpty;
  
  /// Callback when "Add purchase link" is tapped (only used when showAddLinkWhenEmpty is true)
  final VoidCallback? onAddLink;

  const PurchaseButton({
    super.key,
    required this.storeName,
    this.url,
    this.itemName,
    this.isAmazon = false,
    this.isWalmart = false,
    this.icon,
    this.color,
    this.size = PurchaseButtonSize.medium,
    this.showLabel = true,
    this.showAddLinkWhenEmpty = false,
    this.onAddLink,
  }) : assert(
          url != null || itemName != null || showAddLinkWhenEmpty,
          'Either url, itemName, or showAddLinkWhenEmpty must be provided',
        );

  /// Create an Amazon purchase button
  factory PurchaseButton.amazon({
    String? url,
    String? itemName,
    PurchaseButtonSize size = PurchaseButtonSize.medium,
    bool showLabel = true,
    bool showAddLinkWhenEmpty = false,
    VoidCallback? onAddLink,
  }) {
    return PurchaseButton(
      storeName: 'Amazon',
      url: url,
      itemName: itemName,
      isAmazon: true,
      icon: Icons.shopping_bag_outlined,
      color: const Color(0xFFFF9900), // Amazon orange
      size: size,
      showLabel: showLabel,
      showAddLinkWhenEmpty: showAddLinkWhenEmpty,
      onAddLink: onAddLink,
    );
  }

  /// Create a Walmart purchase button
  factory PurchaseButton.walmart({
    String? url,
    String? itemName,
    PurchaseButtonSize size = PurchaseButtonSize.medium,
    bool showLabel = true,
    bool showAddLinkWhenEmpty = false,
    VoidCallback? onAddLink,
  }) {
    return PurchaseButton(
      storeName: 'Walmart',
      url: url,
      itemName: itemName,
      isWalmart: true,
      icon: Icons.store_outlined,
      color: const Color(0xFF0071CE), // Walmart blue
      size: size,
      showLabel: showLabel,
      showAddLinkWhenEmpty: showAddLinkWhenEmpty,
      onAddLink: onAddLink,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    final effectiveIcon = icon ?? Icons.shopping_cart_outlined;
    final effectiveSize = _getSizeValues(size);
    
    // Check if we should show "Add purchase link" mode
    final hasUrl = url != null && url!.trim().isNotEmpty;
    final showAddLink = showAddLinkWhenEmpty && !hasUrl && onAddLink != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: showAddLink ? onAddLink : () => _launchUrl(context),
        borderRadius: BorderRadius.circular(effectiveSize.borderRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: effectiveSize.verticalPadding,
            horizontal: effectiveSize.horizontalPadding,
          ),
          decoration: BoxDecoration(
            color: showAddLink 
                ? effectiveColor.withOpacity(0.05)
                : effectiveColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(effectiveSize.borderRadius),
            border: Border.all(
              color: showAddLink
                  ? effectiveColor.withOpacity(0.2)
                  : effectiveColor.withOpacity(0.3),
              width: showAddLink ? 1.5 : 1,
              style: showAddLink ? BorderStyle.solid : BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                showAddLink ? Icons.add_link : effectiveIcon,
                size: effectiveSize.iconSize,
                color: effectiveColor,
              ),
              if (showLabel) ...[
                SizedBox(width: effectiveSize.spacing),
                Text(
                  showAddLink 
                      ? 'Add purchase link' 
                      : (hasUrl ? 'Buy now' : storeName),
                  style: TextStyle(
                    fontSize: effectiveSize.fontSize,
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchUrl(BuildContext context) async {
    String finalUrl = '';
    try {
      // Determine the final URL to use
      if (url != null && url!.trim().isNotEmpty) {
        // Validate the URL first
        bool isValidUrl = false;
        try {
          final testUri = Uri.parse(url!.trim());
          isValidUrl = testUri.hasScheme && 
                      (testUri.scheme == 'http' || testUri.scheme == 'https') &&
                      testUri.hasAuthority;
        } catch (e) {
          isValidUrl = false;
        }

        // If URL is valid, use it (even if it doesn't match store type - user might have custom link)
        if (isValidUrl) {
          // If URL matches the expected store type, use it with affiliate tag processing
          if (isAmazon && PurchaseLinkService.isAmazonUrl(url!)) {
            finalUrl = PurchaseLinkService.generateAmazonLink(
              itemName: itemName ?? '',
              customUrl: url!,
            );
          } else if (isWalmart && PurchaseLinkService.isWalmartUrl(url!)) {
            finalUrl = PurchaseLinkService.generateWalmartLink(
              itemName: itemName ?? '',
              customUrl: url!,
            );
          } else {
            // URL is valid but doesn't match store type - use it as-is (user-provided custom link)
            // This allows users to use any valid URL they want
            finalUrl = url!.trim();
          }
        } else {
          // URL is invalid, generate from item name
          if (itemName != null && itemName!.trim().isNotEmpty) {
            if (isAmazon) {
              finalUrl = PurchaseLinkService.generateAmazonLink(itemName: itemName!);
            } else if (isWalmart) {
              finalUrl = PurchaseLinkService.generateWalmartLink(itemName: itemName!);
            } else {
              final encodedName = Uri.encodeComponent(itemName!.trim());
              finalUrl = 'https://www.google.com/search?q=$encodedName';
            }
          } else {
            throw Exception('No valid URL or item name provided');
          }
        }
      } else if (itemName != null && itemName!.trim().isNotEmpty) {
        // Generate URL from item name
        if (isAmazon) {
          finalUrl = PurchaseLinkService.generateAmazonLink(itemName: itemName!);
        } else if (isWalmart) {
          finalUrl = PurchaseLinkService.generateWalmartLink(itemName: itemName!);
        } else {
          // Fallback: use itemName as search query
          final encodedName = Uri.encodeComponent(itemName!.trim());
          finalUrl = 'https://www.google.com/search?q=$encodedName';
        }
      } else {
        throw Exception('No URL or item name provided');
      }

      // Ensure URL is trimmed and valid
      finalUrl = finalUrl.trim();
      if (finalUrl.isEmpty) {
        throw Exception('Generated URL is empty');
      }

      // Parse and validate final URL
      Uri uri;
      try {
        uri = Uri.parse(finalUrl);
        
        // Ensure URL has proper scheme
        if (!uri.hasScheme) {
          // Try adding https://
          uri = Uri.parse('https://$finalUrl');
        }
        
        // Validate URI structure
      if (!uri.hasScheme || (!uri.hasAuthority && uri.scheme != 'http' && uri.scheme != 'https')) {
          throw FormatException('Invalid URL format: $finalUrl');
      }

        // Ensure scheme is http or https
        if (uri.scheme != 'http' && uri.scheme != 'https') {
          throw FormatException('URL must use http or https scheme: $finalUrl');
        }
      } catch (e) {
        throw Exception('Formato de URL inválido: $finalUrl. Error: $e');
      }

      // Try to launch the URL
      // Note: canLaunchUrl can be unreliable on some platforms, so we'll try launching anyway
      bool canLaunch = false;
      try {
        canLaunch = await canLaunchUrl(uri).timeout(
          const Duration(seconds: 2),
          onTimeout: () => false,
        );
      } catch (e) {
        // If canLaunchUrl fails, we'll still try to launch
        canLaunch = false;
      }

      // Try launching with different modes
      bool launched = false;
      
      // First try: external application (opens in browser/app)
      try {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        );
        
        if (launched) {
          return; // Success!
        }
      } catch (e) {
        // Continue to try other modes
      }

      // Second try: platform default (if external failed)
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () => false,
          );
          
          if (launched) {
            return; // Success!
          }
        } catch (e) {
          // Continue to try in-app browser
        }
      }

      // Third try: in-app browser (as last resort)
      if (!launched) {
        try {
          launched = await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          ).timeout(
            const Duration(seconds: 5),
            onTimeout: () => false,
          );
        } catch (e) {
          // All methods failed
        }
      }

      // If all launch attempts failed
      if (!launched) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text('No se pudo abrir la URL: $finalUrl'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Copiar URL',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await Clipboard.setData(ClipboardData(text: finalUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL copiada al portapapeles'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Failed to copy URL to clipboard: $e');
                }
              },
            ),
            ),
          );
        }
        throw Exception('Error al abrir la URL: $finalUrl');
      }
    } catch (e) {
      // Log error for debugging
      debugPrint('PurchaseButton URL launch error: $e');
      
      if (context.mounted) {
        final errorMessage = e.toString();
        final displayMessage = errorMessage.length > 100 
            ? '${errorMessage.substring(0, 100)}...'
            : errorMessage;
            
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir URL: $displayMessage'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Copiar',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  final urlToCopy = finalUrl.isNotEmpty ? finalUrl : (url ?? itemName ?? '');
                  await Clipboard.setData(ClipboardData(text: urlToCopy));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('URL copiada al portapapeles'),
                        backgroundColor: AppColors.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint('Failed to copy URL: $e');
                }
              },
            ),
          ),
        );
      }
    }
  }

  _SizeValues _getSizeValues(PurchaseButtonSize size) {
    switch (size) {
      case PurchaseButtonSize.small:
        return _SizeValues(
          iconSize: 14,
          fontSize: 11,
          verticalPadding: 6,
          horizontalPadding: 8,
          spacing: 4,
          borderRadius: 8,
        );
      case PurchaseButtonSize.medium:
        return _SizeValues(
          iconSize: 18,
          fontSize: 13,
          verticalPadding: 10,
          horizontalPadding: 12,
          spacing: 6,
          borderRadius: 10,
        );
      case PurchaseButtonSize.large:
        return _SizeValues(
          iconSize: 22,
          fontSize: 15,
          verticalPadding: 14,
          horizontalPadding: 16,
          spacing: 8,
          borderRadius: 12,
        );
    }
  }
}

/// Button size options
enum PurchaseButtonSize {
  small,
  medium,
  large,
}

class _SizeValues {
  final double iconSize;
  final double fontSize;
  final double verticalPadding;
  final double horizontalPadding;
  final double spacing;
  final double borderRadius;

  _SizeValues({
    required this.iconSize,
    required this.fontSize,
    required this.verticalPadding,
    required this.horizontalPadding,
    required this.spacing,
    required this.borderRadius,
  });
}

