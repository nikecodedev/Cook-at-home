import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/pantry_provider.dart';
import '../../../../models/pantry_item_model.dart';
import '../../../../models/user_store_model.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/translations.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/recipe_recommendation_service.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/localization/app_localizations.dart';
import 'barcode_scanner_screen.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../models/product_model.dart';
import '../../../../services/canonical_ingredient_service.dart';
import '../../../../services/ingredient_price_service.dart';
import 'package:uuid/uuid.dart';

class PantryEditScreen extends ConsumerStatefulWidget {
  final PantryItem? item;
  /// When opening from barcode scan on pantry list, product to prefill the form
  final Product? productForPrefill;

  const PantryEditScreen({super.key, this.item, this.productForPrefill});

  @override
  ConsumerState<PantryEditScreen> createState() => _PantryEditScreenState();
}

class _PantryEditScreenState extends ConsumerState<PantryEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _categoryController;
  late TextEditingController _amazonUrlController;
  late TextEditingController _walmartUrlController;
  late TextEditingController _priceController;
  DateTime? _expirationDate;
  String? _canonicalIngredientId; // Store canonical ingredient ID from scanned product
  bool _priceLoading = false;
  late List<CustomStoreLink> _customStores;

  @override
  void initState() {
    super.initState();
    final prefillFromProduct = widget.productForPrefill;
    final name = widget.item?.name ?? prefillFromProduct?.name ?? '';
    final unit = widget.item?.unit ?? prefillFromProduct?.suggestedUnit ?? 'pieces';
    final category = widget.item?.category ?? prefillFromProduct?.category ?? '';
    _nameController = TextEditingController(text: name);
    _quantityController = TextEditingController(
      text: widget.item?.quantity.toString() ?? '1',
    );
    _unitController = TextEditingController(text: unit);
    _categoryController = TextEditingController(text: category);
    _amazonUrlController = TextEditingController(text: widget.item?.amazonUrl ?? '');
    _walmartUrlController = TextEditingController(text: widget.item?.walmartUrl ?? '');
    _priceController = TextEditingController();
    _expirationDate = widget.item?.expirationDate;
    _canonicalIngredientId = widget.item?.canonicalIngredientId ?? prefillFromProduct?.canonicalIngredientId;
    _customStores = List.from(widget.item?.customStores ?? []);
    if (_canonicalIngredientId != null && _canonicalIngredientId!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserPrice());
    }
  }

  Future<void> _loadUserPrice() async {
    final canonicalId = _canonicalIngredientId;
    final userId = ref.read(currentUserIdProvider);
    if (canonicalId == null || canonicalId.isEmpty || userId == null) return;
    setState(() => _priceLoading = true);
    try {
      final priceService = ref.read(ingredientPriceServiceProvider);
      final price = await priceService.getUserIngredientPrice(canonicalId, userId);
      if (mounted && _canonicalIngredientId == canonicalId) {
        final override = price?.userOverridePrice ?? price?.averagePrice;
        if (override != null && override > 0) {
          _priceController.text = override.toStringAsFixed(2);
        }
      }
    } catch (e) {
      Logger.error('Error loading user price', e, null, 'PantryEditScreen');
    } finally {
      if (mounted) setState(() => _priceLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _categoryController.dispose();
    _amazonUrlController.dispose();
    _walmartUrlController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _selectExpirationDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 years from now
      locale: const Locale('es', 'ES'), // Spanish locale
      cancelText: 'Cancelar',
      confirmText: 'OK',
      helpText: 'Seleccionar fecha',
    );
    if (picked != null && picked != _expirationDate) {
      setState(() {
        _expirationDate = picked;
      });
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final now = DateTime.now();

    // Format ingredient name consistently for storage
    final formattedName = RecipeRecommendationService.formatIngredientNameForStorage(
      _nameController.text.trim(),
    );

    final item = PantryItem(
      id: widget.item?.id ?? const Uuid().v4(),
      name: formattedName,
      canonicalIngredientId: _canonicalIngredientId, // Include canonical ingredient ID
      quantity: quantity,
      unit: _unitController.text.trim(),
      category: _categoryController.text.trim(),
      expirationDate: _expirationDate,
      addedAt: widget.item?.addedAt ?? now,
      amazonUrl: _amazonUrlController.text.trim().isEmpty 
          ? null 
          : _amazonUrlController.text.trim(),
      walmartUrl: _walmartUrlController.text.trim().isEmpty 
          ? null 
          : _walmartUrlController.text.trim(),
      customStores: _customStores,
    );

    try {
      if (widget.item == null) {
        await ref.read(pantryControllerProvider.notifier).addPantryItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingrediente agregado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        await ref.read(pantryControllerProvider.notifier).updatePantryItem(item);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ingrediente actualizado exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      // Save user price override when canonical ingredient is set
      final canonicalId = _canonicalIngredientId;
      final userId = ref.read(currentUserIdProvider);
      if (canonicalId != null && canonicalId.isNotEmpty && userId != null) {
        final priceText = _priceController.text.trim();
        final overridePrice = priceText.isEmpty ? null : double.tryParse(priceText);
        try {
          await ref.read(ingredientPriceServiceProvider).setUserOverridePrice(
            userId: userId,
            canonicalIngredientId: canonicalId,
            overridePrice: overridePrice,
          );
        } catch (priceError) {
          Logger.error('Failed to save price override', priceError, null, 'PantryEditScreen');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Precio no actualizado: ${priceError.toString()}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar ingrediente: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Descartar',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(pantryControllerProvider).isLoading;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.item == null ? 'Agregar Nuevo Ingrediente' : 'Editar Ingrediente',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shopping_basket_outlined,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item == null ? 'Agregar a la Despensa' : 'Actualizar Ingrediente',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completa los detalles a continuación',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Name Field with Scanner Button
              _buildSectionTitle('Detalles del Ingrediente'),
              const SizedBox(height: 8),
              // Helper text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Escanea o escribe el nombre del producto',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.info,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Nombre del Ingrediente',
                      controller: _nameController,
                      prefixIcon: Icons.shopping_basket_outlined,
                      validator: Validators.validateItemName,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Barcode Scanner Button (Phase 2) - More prominent
                  InkWell(
                    onTap: () async {
                      try {
                        final result = await context.push<Product?>(
                          Routes.barcodeScanner,
                        );
                        if (result != null && mounted) {
                          // Product found - auto-fill fields
                          setState(() {
                            _nameController.text = result.name;
                            if (result.category != null) {
                              _categoryController.text = result.category!;
                            }
                            if (result.suggestedUnit != null) {
                              _unitController.text = result.suggestedUnit!;
                            }
                            // Store canonical ingredient ID from product
                            _canonicalIngredientId = result.canonicalIngredientId;
                          });
                          
                          // Load price for the product
                          if (result.canonicalIngredientId != null && 
                              result.canonicalIngredientId!.isNotEmpty) {
                            _loadUserPrice();
                          }
                            
                          // Show success message
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Producto cargado: ${result.name}'),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      } catch (e) {
                        Logger.error('Error scanning barcode', e, null, 'PantryEditScreen');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error al escanear: ${e.toString()}'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Quantity and Unit Row
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Cantidad',
                      controller: _quantityController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.numbers,
                      validator: (value) => Validators.validatePositiveNumber(value, 'Cantidad'),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gray300),
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _unitController.text,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Unidad',
                          prefixIcon: Icon(Icons.straighten),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        items: Units.all.map((unit) {
                          final translatedUnit = Translations.translateUnit(unit);
                          return DropdownMenuItem(
                            value: unit, // Store English value
                            child: Text(
                              translatedUnit,
                              overflow: TextOverflow.ellipsis,
                            ), // Display Spanish translation
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _unitController.text = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Category Field
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: DropdownButtonFormField<String>(
                  value: _categoryController.text.isEmpty ? null : _categoryController.text,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: PantryCategories.all.map((category) {
                    final translatedCategory = Translations.translatePantryCategory(category);
                    return DropdownMenuItem(
                      value: category, // Store English value
                      child: Text(
                        translatedCategory,
                        overflow: TextOverflow.ellipsis,
                      ), // Display Spanish translation
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _categoryController.text = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor selecciona una categoría';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Price section - Always visible for cost tracking
              _buildSectionTitle('Precio (Opcional)'),
              const SizedBox(height: 12),
              if (_priceLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                CustomTextField(
                  label: 'Precio por unidad (\$)',
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: Icons.attach_money,
                  hint: 'ej. 25.50',
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      return Validators.validatePositiveNumber(value, 'Precio');
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
              const SizedBox(height: 8),
              Text(
                'Este precio se usará para calcular el costo de tus recetas y el valor de tu despensa',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),

              // Affiliate URLs Section
              _buildSectionTitle('Enlaces de Compra (Opcional)'),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'URL de Amazon',
                controller: _amazonUrlController,
                prefixIcon: Icons.shopping_bag_outlined,
                keyboardType: TextInputType.url,
                hint: 'https://amazon.com/...',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    return Validators.validateUrl(value);
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'URL de Walmart',
                controller: _walmartUrlController,
                prefixIcon: Icons.store_outlined,
                keyboardType: TextInputType.url,
                hint: 'https://walmart.com/...',
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    return Validators.validateUrl(value);
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // My Stores Section
              _buildSectionTitle('Mis Tiendas (Opcional)'),
              const SizedBox(height: 12),
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
                          'Tus tiendas favoritas',
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
                      'Agrega enlaces a tiendas donde compras este producto',
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
              if (_customStores.isNotEmpty) ...[
                ..._customStores.asMap().entries.map((entry) {
                  final index = entry.key;
                  final store = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                            size: 18,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                store.storeName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                store.url,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              color: AppColors.error,
                              size: 16,
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              _customStores.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
              
              // Add custom store button
              OutlinedButton.icon(
                onPressed: _showAddCustomStoreDialog,
                icon: Icon(
                  Icons.add_business_outlined,
                  size: 20,
                  color: AppColors.secondary,
                ),
                label: const Text(
                  'Agregar mi tienda',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: BorderSide(color: AppColors.secondary.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Expiration Date Section
              _buildSectionTitle('Fecha de Vencimiento'),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _selectExpirationDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gray300),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.calendar_today,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Fecha de Vencimiento',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _expirationDate != null
                                    ? dateFormat.format(_expirationDate!)
                                    : 'Sin fecha de vencimiento (Opcional)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _expirationDate != null
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                  fontWeight: _expirationDate != null
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_expirationDate != null)
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: AppColors.error,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _expirationDate = null;
                              });
                            },
                          )
                        else
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomButton(
                  text: widget.item == null ? 'Agregar a la Despensa' : 'Actualizar Ingrediente',
                  onPressed: isLoading ? null : _saveItem,
                  isLoading: isLoading,
                  icon: widget.item == null ? Icons.add : Icons.check,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Show dialog to add a custom store
  void _showAddCustomStoreDialog() {
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
                  hintText: 'ej., Costco, HEB, Mi Tienda Local',
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
                  hintText: 'https://tienda.com/producto',
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
                  final url = value.trim();
                  if (!url.startsWith('http://') && !url.startsWith('https://')) {
                    return 'La URL debe comenzar con http:// o https://';
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
                setState(() {
                  _customStores.add(CustomStoreLink(
                    storeName: storeNameController.text.trim(),
                    url: urlController.text.trim(),
                  ));
                });
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
}

