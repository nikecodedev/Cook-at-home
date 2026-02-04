import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/purchase_link_service.dart';
import '../theme/app_colors.dart';

/// Store type enum for purchase buttons
enum StoreType { amazon, walmart }

/// Smart purchase button that handles the complete purchase link flow:
/// 1. If link exists → Open directly (shows "Comprar")
/// 2. If no link → Show options: Add manually, Search Amazon, Search Walmart (shows "Agregar enlace")
/// 3. If user doesn't add → Auto-search with ingredient name
class SmartPurchaseButton extends StatelessWidget {
  /// The ingredient/item name for searching
  final String itemName;

  /// Existing Amazon link (if saved)
  final String? amazonLink;

  /// Existing Walmart link (if saved)
  final String? walmartLink;

  /// Callback when user saves a new link
  final void Function(String? amazonUrl, String? walmartUrl)? onLinksUpdated;

  /// Button size
  final SmartPurchaseButtonSize size;

  /// Whether to show compact mode (icons only)
  final bool compact;

  const SmartPurchaseButton({
    super.key,
    required this.itemName,
    this.amazonLink,
    this.walmartLink,
    this.onLinksUpdated,
    this.size = SmartPurchaseButtonSize.medium,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasAmazonLink = amazonLink != null && amazonLink!.trim().isNotEmpty;
    final hasWalmartLink = walmartLink != null && walmartLink!.trim().isNotEmpty;
    final sizeValues = _getSizeValues(size);

    return Row(
      children: [
        // Amazon button
        Expanded(
          child: _StoreButton(
            storeType: StoreType.amazon,
            hasLink: hasAmazonLink,
            existingLink: amazonLink,
            itemName: itemName,
            sizeValues: sizeValues,
            compact: compact,
            onLinksUpdated: onLinksUpdated,
          ),
        ),
        SizedBox(width: sizeValues.spacing),
        // Walmart button
        Expanded(
          child: _StoreButton(
            storeType: StoreType.walmart,
            hasLink: hasWalmartLink,
            existingLink: walmartLink,
            itemName: itemName,
            sizeValues: sizeValues,
            compact: compact,
            onLinksUpdated: onLinksUpdated,
          ),
        ),
      ],
    );
  }

  _SizeValues _getSizeValues(SmartPurchaseButtonSize size) {
    switch (size) {
      case SmartPurchaseButtonSize.small:
        return _SizeValues(
          iconSize: 14,
          fontSize: 11,
          verticalPadding: 6,
          horizontalPadding: 8,
          spacing: 6,
          borderRadius: 8,
        );
      case SmartPurchaseButtonSize.medium:
        return _SizeValues(
          iconSize: 18,
          fontSize: 13,
          verticalPadding: 10,
          horizontalPadding: 12,
          spacing: 8,
          borderRadius: 10,
        );
      case SmartPurchaseButtonSize.large:
        return _SizeValues(
          iconSize: 22,
          fontSize: 15,
          verticalPadding: 14,
          horizontalPadding: 16,
          spacing: 10,
          borderRadius: 12,
        );
    }
  }
}

/// Individual store button
class _StoreButton extends StatelessWidget {
  final StoreType storeType;
  final bool hasLink;
  final String? existingLink;
  final String itemName;
  final _SizeValues sizeValues;
  final bool compact;
  final void Function(String? amazonUrl, String? walmartUrl)? onLinksUpdated;

  const _StoreButton({
    required this.storeType,
    required this.hasLink,
    required this.existingLink,
    required this.itemName,
    required this.sizeValues,
    required this.compact,
    this.onLinksUpdated,
  });

  Color get _storeColor => storeType == StoreType.amazon
      ? const Color(0xFFFF9900) // Amazon orange
      : const Color(0xFF0071CE); // Walmart blue

  String get _storeName => storeType == StoreType.amazon ? 'Amazon' : 'Walmart';

  IconData get _storeIcon => storeType == StoreType.amazon
      ? Icons.shopping_bag_outlined
      : Icons.store_outlined;

  @override
  Widget build(BuildContext context) {
    // Different appearance and text for "has link" vs "no link" states
    final buttonIcon = hasLink ? _storeIcon : Icons.add_link;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleTap(context),
        onLongPress: hasLink ? () => _showLinkOptions(context) : null,
        borderRadius: BorderRadius.circular(sizeValues.borderRadius),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: sizeValues.verticalPadding,
            horizontal: sizeValues.horizontalPadding,
          ),
          decoration: BoxDecoration(
            gradient: hasLink
                ? LinearGradient(
                    colors: [
                      _storeColor.withValues(alpha: 0.2),
                      _storeColor.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: hasLink ? null : _storeColor.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(sizeValues.borderRadius),
            border: Border.all(
              color: _storeColor.withValues(alpha: hasLink ? 0.5 : 0.2),
              width: hasLink ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                buttonIcon,
                size: sizeValues.iconSize,
                color: _storeColor,
              ),
              if (!compact) ...[
                SizedBox(width: sizeValues.spacing - 2),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Always show store name (Amazon/Walmart)
                      Text(
                        _storeName,
                        style: TextStyle(
                          fontSize: sizeValues.fontSize,
                          fontWeight: FontWeight.w700,
                          color: _storeColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasLink) ...[
                        SizedBox(width: sizeValues.spacing - 4),
                        Icon(
                          Icons.open_in_new,
                          size: sizeValues.iconSize - 4,
                          color: _storeColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (hasLink && existingLink != null) {
      // Case 1: Link exists → Open directly
      await _launchUrl(context, existingLink!);
    } else {
      // Case 2 & 3: No link → Show options bottom sheet
      await _showOptionsBottomSheet(context);
    }
  }

  /// Show options when long-pressing on a saved link
  Future<void> _showLinkOptions(BuildContext context) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Opciones de enlace',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Open link
                ListTile(
                  leading: Icon(Icons.open_in_new, color: _storeColor),
                  title: const Text('Abrir enlace'),
                  subtitle: Text(
                    existingLink ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  onTap: () => Navigator.pop(context, 'open'),
                ),

                // Edit link
                ListTile(
                  leading: Icon(Icons.edit, color: _storeColor),
                  title: const Text('Cambiar enlace'),
                  onTap: () => Navigator.pop(context, 'edit'),
                ),

                // Copy link
                ListTile(
                  leading: Icon(Icons.copy, color: _storeColor),
                  title: const Text('Copiar enlace'),
                  onTap: () => Navigator.pop(context, 'copy'),
                ),

                // Delete link
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Eliminar enlace', style: TextStyle(color: AppColors.error)),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == null || !context.mounted) return;

    switch (result) {
      case 'open':
        await _launchUrl(context, existingLink!);
        break;
      case 'edit':
        final newUrl = await _showAddLinkDialog(context, initialUrl: existingLink);
        if (newUrl != null && newUrl.isNotEmpty && context.mounted) {
          _saveLink(context, newUrl);
        }
        break;
      case 'copy':
        await Clipboard.setData(ClipboardData(text: existingLink!));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text('Enlace copiado al portapapeles'),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        break;
      case 'delete':
        _deleteLink(context);
        break;
    }
  }

  Future<void> _showOptionsBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<_BottomSheetResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PurchaseOptionsBottomSheet(
        itemName: itemName,
        storeType: storeType,
        storeColor: _storeColor,
        storeName: _storeName,
      ),
    );

    if (result == null || !context.mounted) return;

    switch (result.action) {
      case _BottomSheetAction.addManually:
        // Show URL input dialog
        if (context.mounted) {
          final newUrl = await _showAddLinkDialog(context);
          if (newUrl != null && newUrl.isNotEmpty && context.mounted) {
            // Save the link and show confirmation
            _saveAndOpenLink(context, newUrl);
          }
        }
        break;

      case _BottomSheetAction.searchAmazon:
        // Search on Amazon
        final searchUrl = PurchaseLinkService.generateAmazonLink(itemName: itemName);
        if (context.mounted) {
          await _launchUrl(context, searchUrl);
          // Offer to save the link after searching
          if (context.mounted) {
            _offerToSaveLink(context, StoreType.amazon);
          }
        }
        break;

      case _BottomSheetAction.searchWalmart:
        // Search on Walmart
        final searchUrl = PurchaseLinkService.generateWalmartLink(itemName: itemName);
        if (context.mounted) {
          await _launchUrl(context, searchUrl);
          // Offer to save the link after searching
          if (context.mounted) {
            _offerToSaveLink(context, StoreType.walmart);
          }
        }
        break;

      case _BottomSheetAction.quickSearch:
        // Quick search on the current store
        final searchUrl = storeType == StoreType.amazon
            ? PurchaseLinkService.generateAmazonLink(itemName: itemName)
            : PurchaseLinkService.generateWalmartLink(itemName: itemName);
        if (context.mounted) {
          await _launchUrl(context, searchUrl);
          // Offer to save the link after searching
          if (context.mounted) {
            _offerToSaveLink(context, storeType);
          }
        }
        break;
    }
  }

  /// Offer to save a product link after the user searches
  void _offerToSaveLink(BuildContext context, StoreType searchedStore) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Encontraste el producto? Copia el enlace y guárdalo',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: searchedStore == StoreType.amazon
            ? const Color(0xFFFF9900)
            : const Color(0xFF0071CE),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Agregar enlace',
          textColor: Colors.white,
          onPressed: () async {
            final newUrl = await _showAddLinkDialog(context);
            if (newUrl != null && newUrl.isNotEmpty && context.mounted) {
              _saveLink(context, newUrl);
            }
          },
        ),
      ),
    );
  }

  Future<String?> _showAddLinkDialog(BuildContext context, {String? initialUrl}) async {
    final controller = TextEditingController(text: initialUrl);
    String? validationError;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _storeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_storeIcon, color: _storeColor, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                initialUrl != null ? 'Editar enlace' : 'Agregar enlace de compra',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: _storeColor, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pega el enlace del producto "$itemName" de $_storeName',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.url,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'https://www.${_storeName.toLowerCase()}.com/...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.link, color: _storeColor),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _storeColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                  errorText: validationError,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.paste_rounded),
                    color: _storeColor,
                    onPressed: () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        controller.text = data!.text!;
                        setState(() => validationError = null);
                      }
                    },
                    tooltip: 'Pegar del portapapeles',
                  ),
                ),
                onChanged: (_) {
                  if (validationError != null) {
                    setState(() => validationError = null);
                  }
                },
              ),
              const SizedBox(height: 12),
              // Helper text
              Row(
                children: [
                  Icon(Icons.help_outline, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tip: Busca el producto en $_storeName, copia el enlace de la página del producto y pégalo aquí',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                final url = controller.text.trim();

                // Validate URL
                if (url.isEmpty) {
                  setState(() => validationError = 'Por favor ingresa un enlace');
                  return;
                }

                // Add scheme if missing
                String urlToValidate = url;
                if (!url.startsWith('http://') && !url.startsWith('https://')) {
                  urlToValidate = 'https://$url';
                }

                try {
                  final uri = Uri.parse(urlToValidate);
                  if (!uri.hasScheme || !uri.hasAuthority) {
                    setState(() => validationError = 'Enlace inválido - verifica el formato');
                    return;
                  }

                  // Warn if not the expected store but allow it
                  final isExpectedStore = storeType == StoreType.amazon
                      ? PurchaseLinkService.isAmazonUrl(urlToValidate)
                      : PurchaseLinkService.isWalmartUrl(urlToValidate);

                  if (!isExpectedStore) {
                    // Show warning but allow
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Nota: Este enlace no parece ser de $_storeName'),
                        backgroundColor: AppColors.warning,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }

                  Navigator.pop(context, urlToValidate);
                } catch (e) {
                  setState(() => validationError = 'Enlace inválido');
                }
              },
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Guardar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _storeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveLink(BuildContext context, String newUrl) {
    // Notify parent about the new link
    if (onLinksUpdated != null) {
      if (storeType == StoreType.amazon) {
        onLinksUpdated!(newUrl, null);
      } else {
        onLinksUpdated!(null, newUrl);
      }
    }

    // Show success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Enlace de $_storeName guardado'),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deleteLink(BuildContext context) {
    // Notify parent to remove the link
    if (onLinksUpdated != null) {
      if (storeType == StoreType.amazon) {
        onLinksUpdated!('', null); // Empty string to indicate deletion
      } else {
        onLinksUpdated!(null, '');
      }
    }

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.delete_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Enlace de $_storeName eliminado'),
          ],
        ),
        backgroundColor: AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _saveAndOpenLink(BuildContext context, String newUrl) {
    // Save the link
    _saveLink(context, newUrl);

    // Open the link
    _launchUrl(context, newUrl);
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      String finalUrl = url.trim();
      if (finalUrl.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hay enlace para abrir'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Add scheme if missing
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }

      // Do not open app/share routes (recipe deep links) as retailer links
      final uriParsed = Uri.tryParse(finalUrl);
      if (uriParsed != null &&
          (uriParsed.host.contains('cocinaentucasa.com') ||
              uriParsed.host.contains('cocinaencasa.com')) &&
          uriParsed.pathSegments.isNotEmpty &&
          uriParsed.pathSegments.first == 'recipe') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este enlace es para compartir la receta, no para comprar. Agrega un enlace de Amazon o Walmart.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      // Process through affiliate service if it's a store URL
      if (storeType == StoreType.amazon && PurchaseLinkService.isAmazonUrl(finalUrl)) {
        finalUrl = PurchaseLinkService.generateAmazonLink(
          itemName: itemName,
          customUrl: finalUrl,
        );
      } else if (storeType == StoreType.walmart && PurchaseLinkService.isWalmartUrl(finalUrl)) {
        finalUrl = PurchaseLinkService.generateWalmartLink(
          itemName: itemName,
          customUrl: finalUrl,
        );
      }

      final uri = Uri.parse(finalUrl);

      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );

      if (!launched) {
        launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => false,
        );
      }

      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('No se pudo abrir el enlace'),
                const SizedBox(height: 4),
                Text(
                  finalUrl,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            backgroundColor: AppColors.error,
            action: SnackBarAction(
              label: 'Copiar',
              textColor: Colors.white,
              onPressed: () {
                Clipboard.setData(ClipboardData(text: finalUrl));
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al abrir enlace: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

/// Bottom sheet for purchase options
class _PurchaseOptionsBottomSheet extends StatelessWidget {
  final String itemName;
  final StoreType storeType;
  final Color storeColor;
  final String storeName;

  const _PurchaseOptionsBottomSheet({
    required this.itemName,
    required this.storeType,
    required this.storeColor,
    required this.storeName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title with icon
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: storeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shopping_cart_outlined, color: storeColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Comprar "$itemName"',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF212121),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Elige cómo quieres buscar este ingrediente',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Option 1: Add link manually (highlighted)
              _OptionTile(
                icon: Icons.add_link,
                iconColor: AppColors.primary,
                title: 'Agregar enlace de producto',
                subtitle: 'Pega un enlace específico que ya tengas',
                isHighlighted: true,
                onTap: () => Navigator.pop(
                  context,
                  _BottomSheetResult(_BottomSheetAction.addManually),
                ),
              ),
              const SizedBox(height: 12),

              // Divider with text
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'O buscar en tiendas',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 12),

              // Option 2: Search on Amazon
              _OptionTile(
                icon: Icons.shopping_bag_outlined,
                iconColor: const Color(0xFFFF9900),
                title: 'Buscar en Amazon',
                subtitle: 'Abrir búsqueda de "$itemName"',
                onTap: () => Navigator.pop(
                  context,
                  _BottomSheetResult(_BottomSheetAction.searchAmazon),
                ),
              ),
              const SizedBox(height: 12),

              // Option 3: Search on Walmart
              _OptionTile(
                icon: Icons.store_outlined,
                iconColor: const Color(0xFF0071CE),
                title: 'Buscar en Walmart',
                subtitle: 'Abrir búsqueda de "$itemName"',
                onTap: () => Navigator.pop(
                  context,
                  _BottomSheetResult(_BottomSheetAction.searchWalmart),
                ),
              ),
              const SizedBox(height: 24),

              // Quick search button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(
                    context,
                    _BottomSheetResult(_BottomSheetAction.quickSearch),
                  ),
                  icon: const Icon(Icons.search),
                  label: Text('Búsqueda rápida en $storeName'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: storeColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Option tile for bottom sheet
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isHighlighted ? 0.12 : 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: iconColor.withValues(alpha: isHighlighted ? 0.4 : 0.15),
              width: isHighlighted ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w600,
                        color: const Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet result
class _BottomSheetResult {
  final _BottomSheetAction action;

  _BottomSheetResult(this.action);
}

/// Bottom sheet actions
enum _BottomSheetAction {
  addManually,
  searchAmazon,
  searchWalmart,
  quickSearch,
}

/// Button size options
enum SmartPurchaseButtonSize {
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
