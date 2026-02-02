import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../models/product_model.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/translations.dart';
import '../../../../services/storage/firebase_storage_service.dart';
import 'dart:io';

/// Screen for adding a new product after scanning a barcode
/// Changed from "Contribute to Global Catalog" to local product creation
class ContributeProductScreen extends ConsumerStatefulWidget {
  final String? barcode;

  const ContributeProductScreen({super.key, this.barcode});

  @override
  ConsumerState<ContributeProductScreen> createState() => _ContributeProductScreenState();
}

class _ContributeProductScreenState extends ConsumerState<ContributeProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _barcodeController;
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _priceController;
  late TextEditingController _packageContentController;
  
  String? _selectedCategory;
  String? _selectedUnit;
  String? _selectedPackageUnit;
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.barcode ?? '');
    _nameController = TextEditingController();
    _brandController = TextEditingController();
    _priceController = TextEditingController();
    _packageContentController = TextEditingController();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _packageContentController.dispose();
    super.dispose();
  }

  /// Pick image from gallery or camera
  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await showModalBottomSheet<XFile>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar de Galería'),
                onTap: () async {
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar Foto'),
                onTap: () async {
                  final image = await picker.pickImage(source: ImageSource.camera);
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        ),
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Logger.error('Error picking image', e, null, 'ContributeProductScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Save product locally and return for pantry addition
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productService = ref.read(productServiceProvider);
      final canonicalService = ref.read(canonicalIngredientServiceProvider);
      final userId = ref.read(currentUserIdProvider);
      final barcode = _barcodeController.text.trim();
      final productName = _nameController.text.trim();
      
      // Check if product with this barcode already exists
      final existing = await productService.getProductByBarcode(barcode);
      if (existing != null) {
        // Product already exists, return it
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Producto encontrado! Se completarán los datos automáticamente.'),
              backgroundColor: AppColors.success,
              duration: Duration(seconds: 2),
            ),
          );
          context.pop(existing);
        }
        return;
      }

      // Create or find canonical ingredient based on product name
      String? canonicalIngredientId;
      try {
        canonicalIngredientId = await canonicalService.createOrGetCanonicalIngredient(
          name: productName,
          category: _selectedCategory,
          defaultUnit: _selectedUnit,
        );
      } catch (e) {
        Logger.warning('Could not create canonical ingredient, continuing without', 'ContributeProductScreen');
        // Continue without canonical ingredient - not critical
      }

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        try {
          final storageService = FirebaseStorageService();
          imageUrl = await storageService.uploadProductImage(
            barcode,
            _selectedImage!,
          );
        } catch (e) {
          Logger.warning('Failed to upload image, continuing without image', 'ContributeProductScreen');
          // Continue without image - not critical
        }
      }

      // Parse package content
      final packageContentText = _packageContentController.text.trim();
      final packageContent = packageContentText.isNotEmpty 
          ? double.tryParse(packageContentText) 
          : null;

      // Create product in database
      final productId = await productService.createProduct(
        barcode: barcode,
        name: productName,
        canonicalIngredientId: canonicalIngredientId ?? '',
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        category: _selectedCategory,
        suggestedUnit: _selectedUnit,
        packageContent: packageContent,
        packageUnit: _selectedPackageUnit,
        imageUrl: imageUrl,
        contributorId: userId,
      );

      final product = await productService.getProductById(productId);
      
      if (product != null && mounted) {
        Logger.success('Product created successfully: $productId', 'ContributeProductScreen');
        
        // Also save user price override if provided
        final priceText = _priceController.text.trim();
        if (priceText.isNotEmpty && canonicalIngredientId != null && userId != null) {
          final price = double.tryParse(priceText);
          if (price != null && price > 0) {
            try {
              await ref.read(ingredientPriceServiceProvider).setUserOverridePrice(
                userId: userId,
                canonicalIngredientId: canonicalIngredientId,
                overridePrice: price,
              );
            } catch (e) {
              Logger.warning('Could not save price override', 'ContributeProductScreen');
            }
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Producto guardado exitosamente!'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
        context.pop(product);
      }
    } catch (e, stackTrace) {
      Logger.error('Error saving product', e, stackTrace, 'ContributeProductScreen');
      setState(() {
        _errorMessage = 'Error al guardar producto: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Agregar Producto',
          style: TextStyle(
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
              // Header
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
                        Icons.inventory_2_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nuevo Producto',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Completa los datos del producto escaneado',
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

              // Helper text
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Escanea o escribe el nombre del producto para agregarlo a tu despensa',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.info,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),

              // Barcode field
              _buildSectionTitle('Código de Barras'),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Código de Barras (EAN/UPC)',
                controller: _barcodeController,
                prefixIcon: Icons.qr_code,
                keyboardType: TextInputType.number,
                enabled: widget.barcode == null, // Disable if pre-filled from scanner
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El código de barras es requerido';
                  }
                  final barcode = value.trim();
                  if (!RegExp(r'^\d{8,14}$').hasMatch(barcode)) {
                    return 'Formato inválido (debe tener 8-14 dígitos)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Product details section
              _buildSectionTitle('Datos del Producto'),
              const SizedBox(height: 12),
              
              // Product name
              CustomTextField(
                label: 'Nombre del Producto *',
                controller: _nameController,
                prefixIcon: Icons.shopping_basket,
                hint: 'ej. Leche Entera 1L',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre del producto es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Brand (optional)
              CustomTextField(
                label: 'Marca (Opcional)',
                controller: _brandController,
                prefixIcon: Icons.branding_watermark,
                hint: 'ej. Lala, Alpura',
              ),
              const SizedBox(height: 16),

              // Category dropdown with Spanish translations - styled to match CustomTextField
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gray200.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Categoría (Opcional)',
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.category_outlined, color: AppColors.primary, size: 22),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.gray300, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.gray300, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Seleccionar categoría')),
                    ...PantryCategories.all.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(Translations.translatePantryCategory(category)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Suggested unit dropdown with Spanish translations - styled to match CustomTextField
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gray200.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Unidad Sugerida (Opcional)',
                    labelStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.straighten, color: AppColors.primary, size: 22),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.gray300, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.gray300, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Seleccionar unidad')),
                    ...Units.all.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(Translations.translateUnit(unit)),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedUnit = value;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Package Content Section
              _buildSectionTitle('Contenido del Paquete *'),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Package content amount
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Cantidad',
                      controller: _packageContentController,
                      prefixIcon: Icons.inventory_2_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      hint: 'ej. 500, 1, 12',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Requerido';
                        }
                        final content = double.tryParse(value.trim());
                        if (content == null || content <= 0) {
                          return 'Ingresa un número válido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Package unit dropdown - styled to match CustomTextField
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gray200.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedPackageUnit,
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Unidad',
                          labelStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.straighten_rounded, color: AppColors.primary, size: 22),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.gray300, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.gray300, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.primary, width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.error, width: 1.5),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.error, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Requerido';
                          }
                          return null;
                        },
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Seleccionar')),
                          DropdownMenuItem(value: 'g', child: Text('g (gramos)')),
                          DropdownMenuItem(value: 'kg', child: Text('kg (kilos)')),
                          DropdownMenuItem(value: 'ml', child: Text('ml (mililitros)')),
                          DropdownMenuItem(value: 'L', child: Text('L (litros)')),
                          DropdownMenuItem(value: 'pzas', child: Text('pzas (piezas)')),
                          DropdownMenuItem(value: 'oz', child: Text('oz (onzas)')),
                          DropdownMenuItem(value: 'lb', child: Text('lb (libras)')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPackageUnit = value;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Indica el contenido del paquete (ej. 500 g, 1 L, 12 pzas). Esto es necesario para calcular costos de recetas y valor de despensa.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),

              // Price section
              _buildSectionTitle('Precio (Opcional)'),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Precio por unidad (\$)',
                controller: _priceController,
                prefixIcon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                hint: 'ej. 25.50',
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final price = double.tryParse(value.trim());
                    if (price == null || price < 0) {
                      return 'Ingresa un precio válido';
                    }
                  }
                  return null;
                },
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

              // Product photo
              _buildSectionTitle('Foto del Producto (Opcional)'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedImage != null ? AppColors.primary : AppColors.gray300,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                icon: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, size: 18, color: AppColors.error),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Toca para agregar foto',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Save button - Clear CTA
              CustomButton(
                text: 'Guardar en mi Despensa',
                onPressed: _isLoading ? null : _saveProduct,
                isLoading: _isLoading,
                icon: Icons.save_rounded,
              ),
              const SizedBox(height: 16),

              // Cancel button
              TextButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
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
}
