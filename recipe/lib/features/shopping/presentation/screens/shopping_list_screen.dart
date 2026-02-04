import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../providers/shopping_list_provider.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../models/shopping_list_model.dart';
import '../../../../models/user_store_model.dart';
import '../../../../core/utils/translations.dart';
import '../../../../core/widgets/smart_purchase_button.dart';
import '../../../../core/utils/validators.dart';

class ShoppingListScreen extends ConsumerWidget {
  final ShoppingList shoppingList;

  const ShoppingListScreen({super.key, required this.shoppingList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(shoppingListItemsStreamProvider(shoppingList.id));
    final isLoading = ref.watch(shoppingListControllerProvider).isLoading;
    final userId = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Lista de Compras',
        subtitle: shoppingList.recipeTitle,
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            onPressed: isLoading
                ? null
                : () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: itemsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return _buildEmptyState(context);
          }

          final checkedCount = items.where((item) => item.isChecked).length;
          final totalCount = items.length;
          final progress = totalCount > 0 ? checkedCount / totalCount : 0.0;

          return Column(
            children: [
              // Progress Header with Estimated Cost
              _buildProgressHeader(context, ref, items, checkedCount, totalCount, progress, userId),
              // Items List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildItemCard(context, ref, item);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => _buildEmptyState(context),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar artículos: $error',
                style: const TextStyle(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(
    BuildContext context,
    WidgetRef ref,
    List<ShoppingListItem> items,
    int checkedCount,
    int totalCount,
    double progress,
    String? userId,
  ) {
    // Calculate estimated cost asynchronously
    final priceService = ref.watch(ingredientPriceServiceProvider);
    
    return FutureBuilder<double>(
      future: _calculateEstimatedCost(items, priceService, userId),
      builder: (context, snapshot) {
        final estimatedCost = snapshot.data;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.gray200.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$checkedCount de $totalCount artículos',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: progress == 1.0
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.gray200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress == 1.0
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              ),
              // Estimated cost display
              if (estimatedCost != null && estimatedCost > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.attach_money_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Costo estimado: \$${estimatedCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<double> _calculateEstimatedCost(
    List<ShoppingListItem> items,
    dynamic priceService,
    String? userId,
  ) async {
    if (userId == null) return 0;
    
    double totalCost = 0;
    for (final item in items) {
      if (item.canonicalIngredientId != null && item.canonicalIngredientId!.isNotEmpty) {
        try {
          final price = await priceService.getUserIngredientPrice(
            item.canonicalIngredientId!,
            userId,
          );
          if (price != null) {
            // Simple cost calculation: price * quantity
            totalCost += price.effectivePrice * item.quantity;
          }
        } catch (e) {
          // Ignore errors for individual items
        }
      }
    }
    return totalCost;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'La Lista de Compras está Vacía',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Todos los artículos han sido eliminados o marcados como comprados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    WidgetRef ref,
    ShoppingListItem item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isChecked
              ? AppColors.success.withOpacity(0.5)
              : AppColors.gray200,
          width: item.isChecked ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: item.isChecked
                ? AppColors.success.withOpacity(0.15)
                : AppColors.gray200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content area
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Large Checkbox - tap to mark as purchased (more intuitive)
                  GestureDetector(
                    onTap: () async {
                      try {
                        await ref.read(shoppingListControllerProvider.notifier).updateItemStatus(
                              listId: shoppingList.id,
                              itemId: item.id,
                              isChecked: !item.isChecked,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    !item.isChecked ? Icons.check_circle : Icons.undo,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    !item.isChecked 
                                        ? 'Marcado como comprado' 
                                        : 'Marcado como no comprado',
                                  ),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al actualizar artículo: ${e.toString()}'),
                              backgroundColor: AppColors.error,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: item.isChecked
                            ? AppColors.success
                            : Colors.transparent,
                        border: Border.all(
                          color: item.isChecked
                              ? AppColors.success
                              : AppColors.gray400,
                          width: 3,
                        ),
                      ),
                      child: item.isChecked
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 24,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Item Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: item.isChecked
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration: item.isChecked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${item.quantity} ${Translations.translateUnit(item.unit)}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons - Edit and Delete buttons side by side for better visibility
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Button - More visible
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        tooltip: 'Editar Artículo',
                        onPressed: () => _showEditDialog(context, ref, item),
                      ),
                      // Delete Button
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                          size: 22,
                        ),
                        tooltip: 'Eliminar Artículo',
                        onPressed: () => _showDeleteItemDialog(context, ref, item),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Purchase Buttons - only show for unchecked items
            if (!item.isChecked) ...[
              const Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SmartPurchaseButton(
                      itemName: item.name,
                      amazonLink: item.amazonLink,
                      walmartLink: item.walmartLink,
                      size: SmartPurchaseButtonSize.medium,
                      onLinksUpdated: (amazonUrl, walmartUrl) {
                        _handleLinkUpdate(context, ref, item, amazonUrl, walmartUrl);
                      },
                    ),
                    // Custom stores - display if any exist
                    if (item.customStores.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.customStores.map((store) {
                          return _buildCustomStoreChip(context, store);
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build a custom store chip button
  Widget _buildCustomStoreChip(BuildContext context, CustomStoreLink store) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _launchCustomStoreUrl(context, store.url),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.secondary.withOpacity(0.15),
                AppColors.secondary.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.secondary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_outlined,
                size: 16,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                store.storeName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.open_in_new,
                size: 12,
                color: AppColors.secondary.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Launch custom store URL (only valid http/https retailer links)
  Future<void> _launchCustomStoreUrl(BuildContext context, String url) async {
    try {
      final trimmed = url.trim();
      if (trimmed.isEmpty) {
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
      String finalUrl = trimmed;
      if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
        finalUrl = 'https://$finalUrl';
      }
      final uri = Uri.tryParse(finalUrl);
      if (uri == null || !uri.hasScheme || (!uri.isScheme('http') && !uri.isScheme('https'))) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Enlace no válido'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
      // Do not open app recipe share links as store links
      if (uri.host.contains('cocinaentucasa.com') || uri.host.contains('cocinaencasa.com')) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Este enlace es para compartir, no para comprar. Agrega un enlace de tienda.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo abrir el enlace'),
              backgroundColor: AppColors.error,
            ),
          );
        }
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

  /// Handle link updates from SmartPurchaseButton
  Future<void> _handleLinkUpdate(
    BuildContext context,
    WidgetRef ref,
    ShoppingListItem item,
    String? amazonUrl,
    String? walmartUrl,
  ) async {
    try {
      // Handle link updates:
      // - null means "don't change this link"
      // - empty string means "delete this link"
      // - non-empty string means "set this as the new link"
      String? newAmazonLink = item.amazonLink;
      String? newWalmartLink = item.walmartLink;

      if (amazonUrl != null) {
        newAmazonLink = amazonUrl.isEmpty ? null : amazonUrl;
      }
      if (walmartUrl != null) {
        newWalmartLink = walmartUrl.isEmpty ? null : walmartUrl;
      }

      await ref.read(shoppingListControllerProvider.notifier).updateShoppingItem(
        listId: shoppingList.id,
        itemId: item.id,
        name: item.name,
        quantity: item.quantity,
        unit: item.unit,
        amazonLink: newAmazonLink,
        walmartLink: newWalmartLink,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Enlace guardado exitosamente'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar enlace: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, ShoppingListItem item) {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(text: item.quantity.toString());
    final unitController = TextEditingController(text: item.unit);
    final amazonController = TextEditingController(text: item.amazonLink ?? '');
    final walmartController = TextEditingController(text: item.walmartLink ?? '');
    final formKey = GlobalKey<FormState>();
    
    // Custom stores state
    List<CustomStoreLink> customStores = List.from(item.customStores);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Form(
          key: formKey,
          child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Editar Artículo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nombre del Artículo *',
                  hintText: 'ej., Tomates Orgánicos',
                  filled: true,
                  fillColor: AppColors.gray50,
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Quantity and Unit
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Cantidad *',
                        hintText: '1.5',
                        filled: true,
                        fillColor: AppColors.gray50,
                        prefixIcon: const Icon(Icons.numbers_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.gray200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: unitController,
                      decoration: InputDecoration(
                        labelText: 'Unidad',
                        hintText: 'lb',
                        filled: true,
                        fillColor: AppColors.gray50,
                        prefixIcon: const Icon(Icons.scale_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.gray200),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.gray200),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Purchase Links Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.link_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Enlaces de Compra (Opcional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agrega enlaces directos para comprar este artículo',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Amazon Link
              TextFormField(
                controller: amazonController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Enlace de Amazon',
                  hintText: 'https://amazon.com/...',
                  helperText: 'Deja vacío para generar automáticamente',
                  filled: true,
                  fillColor: AppColors.gray50,
                  prefixIcon: Icon(
                    Icons.shopping_bag_outlined,
                    color: const Color(0xFFFF9900),
                  ),
                  suffixIcon: amazonController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(
                            Validators.validateOptionalUrl(amazonController.text) == null
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: Validators.validateOptionalUrl(amazonController.text) == null
                                ? AppColors.success
                                : AppColors.error,
                            size: 22,
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFFFF9900), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                ),
                validator: Validators.validateOptionalUrl,
                onChanged: (value) {
                  // Trigger rebuild to show validation icon
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              // Walmart Link
              TextFormField(
                controller: walmartController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Enlace de Walmart',
                  hintText: 'https://walmart.com/...',
                  helperText: 'Deja vacío para generar automáticamente',
                  filled: true,
                  fillColor: AppColors.gray50,
                  prefixIcon: Icon(
                    Icons.store_outlined,
                    color: const Color(0xFF0071CE),
                  ),
                  suffixIcon: walmartController.text.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(
                            Validators.validateOptionalUrl(walmartController.text) == null
                                ? Icons.check_circle
                                : Icons.error_outline,
                            color: Validators.validateOptionalUrl(walmartController.text) == null
                                ? AppColors.success
                                : AppColors.error,
                            size: 22,
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppColors.gray200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: const Color(0xFF0071CE), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.error, width: 2),
                  ),
                ),
                validator: Validators.validateOptionalUrl,
                onChanged: (value) {
                  // Trigger rebuild to show validation icon
                  setState(() {});
                },
              ),
              
              const SizedBox(height: 24),
              
              // My Stores Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 16,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mis Tiendas',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agrega enlaces a tus tiendas favoritas',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Display existing custom stores
              if (customStores.isNotEmpty) ...[
                ...customStores.asMap().entries.map((entry) {
                  final index = entry.key;
                  final store = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.store_outlined,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.storeName,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                store.url,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            setState(() {
                              customStores.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
              
              // Add custom store button
              OutlinedButton.icon(
                onPressed: () => _showAddCustomStoreDialog(
                  context,
                  (storeName, url) {
                    setState(() {
                      customStores.add(CustomStoreLink(
                        storeName: storeName,
                        url: url,
                      ));
                    });
                  },
                ),
                icon: Icon(
                  Icons.add_business_outlined,
                  size: 18,
                  color: AppColors.secondary,
                ),
                label: const Text(
                  'Agregar mi tienda',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(color: AppColors.secondary.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primaryDark,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre del artículo es requerido'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                  return;
                }

                try {
                  final quantity = double.tryParse(quantityController.text) ?? item.quantity;
                  final unit = unitController.text.trim().isEmpty ? '' : unitController.text.trim();
                  
                  // Validate URLs before saving
                  final amazonUrlError = Validators.validateOptionalUrl(amazonController.text.trim());
                  final walmartUrlError = Validators.validateOptionalUrl(walmartController.text.trim());
                  
                  if (amazonUrlError != null || walmartUrlError != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(amazonUrlError ?? walmartUrlError ?? 'Invalid URL'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  
                  await ref
                      .read(shoppingListControllerProvider.notifier)
                      .updateShoppingItem(
                        listId: shoppingList.id,
                        itemId: item.id,
                        name: nameController.text.trim(),
                        quantity: quantity,
                        unit: unit,
                        amazonLink: amazonController.text.trim().isEmpty
                            ? null
                            : amazonController.text.trim(),
                        walmartLink: walmartController.text.trim().isEmpty
                            ? null
                            : walmartController.text.trim(),
                        customStores: customStores,
                      );

                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Artículo actualizado exitosamente'),
                          ],
                        ),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al actualizar artículo: $e'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  /// Show dialog to add a custom store
  void _showAddCustomStoreDialog(
    BuildContext context,
    Function(String storeName, String url) onAdd,
  ) {
    final storeNameController = TextEditingController();
    final urlController = TextEditingController();
    final addStoreFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.add_business_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Agregar Mi Tienda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: addStoreFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: storeNameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Nombre de la tienda *',
                  hintText: 'ej., Mi Tienda Local',
                  filled: true,
                  fillColor: AppColors.gray50,
                  prefixIcon: const Icon(Icons.store_outlined),
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
                    borderSide: BorderSide(color: AppColors.secondary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre de la tienda es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: urlController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'URL del producto *',
                  hintText: 'https://mitienda.com/producto',
                  filled: true,
                  fillColor: AppColors.gray50,
                  prefixIcon: const Icon(Icons.link_outlined),
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
                    borderSide: BorderSide(color: AppColors.secondary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La URL es requerida';
                  }
                  final urlError = Validators.validateOptionalUrl(value.trim());
                  if (urlError != null) {
                    return urlError;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (addStoreFormKey.currentState!.validate()) {
                onAdd(
                  storeNameController.text.trim(),
                  urlController.text.trim(),
                );
                Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteItemDialog(BuildContext context, WidgetRef ref, ShoppingListItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar Artículo',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${item.name}" de la lista?',
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
              try {
                await ref
                    .read(shoppingListControllerProvider.notifier)
                    .deleteShoppingItem(
                      listId: shoppingList.id,
                      itemId: item.id,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Artículo eliminado'),
                      backgroundColor: AppColors.success,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar artículo: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Eliminar Lista de Compras',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta lista de compras? Esta acción no se puede deshacer.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () async {
                try {
                  await ref
                      .read(shoppingListControllerProvider.notifier)
                      .deleteShoppingList(shoppingList.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar lista de compras: ${e.toString()}'),
                      backgroundColor: AppColors.error,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

