import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../models/product_model.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../services/canonical_ingredient_service.dart';
import '../../../../services/storage/firebase_storage_service.dart';
import '../../../../core/constants/firebase_constants.dart';
import 'dart:io';

/// Screen for contributing a new product to the global catalog
/// Shown when a scanned barcode doesn't exist in the database
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
  late TextEditingController _ingredientNameController;
  
  String? _selectedCategory;
  String? _selectedUnit;
  File? _selectedImage;
  String? _canonicalIngredientId;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _barcodeController = TextEditingController(text: widget.barcode ?? '');
    _nameController = TextEditingController();
    _brandController = TextEditingController();
    _ingredientNameController = TextEditingController();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _ingredientNameController.dispose();
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
                title: const Text('Choose from Gallery'),
                onTap: () async {
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
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
            content: Text('Error selecting image: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Find or create canonical ingredient
  Future<void> _findCanonicalIngredient() async {
    final ingredientName = _ingredientNameController.text.trim();
    if (ingredientName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an ingredient name';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final canonicalService = ref.read(canonicalIngredientServiceProvider);
      
      // Try to find existing canonical ingredient
      var canonical = await canonicalService.findCanonicalIngredientByName(ingredientName);
      
      if (canonical == null) {
        // Create new canonical ingredient
        final canonicalId = await canonicalService.createOrGetCanonicalIngredient(
          name: ingredientName,
          category: _selectedCategory,
          defaultUnit: _selectedUnit,
        );
        canonical = await canonicalService.getCanonicalIngredient(canonicalId);
      }

      if (canonical != null) {
        final canonicalId = canonical.id;
        setState(() {
          _canonicalIngredientId = canonicalId;
        });
        Logger.success('Canonical ingredient found/created: ${canonical.name}', 'ContributeProductScreen');
      }
    } catch (e) {
      Logger.error('Error finding canonical ingredient', e, null, 'ContributeProductScreen');
      setState(() {
        _errorMessage = 'Error finding ingredient: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Save product to global catalog
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_canonicalIngredientId == null || _canonicalIngredientId!.isEmpty) {
      setState(() {
        _errorMessage = 'Please find or create a canonical ingredient first';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productService = ref.read(productServiceProvider);
      final userId = ref.read(currentUserIdProvider);
      
      // Check if product with this barcode already exists (duplicate prevention)
      final existing = await productService.getProductByBarcode(_barcodeController.text.trim());
      if (existing != null) {
        setState(() {
          _errorMessage = 'A product with this barcode already exists';
          _isLoading = false;
        });
        return;
      }

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        try {
          final storageService = FirebaseStorageService();
          imageUrl = await storageService.uploadProductImage(
            _barcodeController.text.trim(),
            _selectedImage!,
          );
        } catch (e) {
          Logger.warning('Failed to upload image, continuing without image', 'ContributeProductScreen');
          // Continue without image - not critical
        }
      }

      // Create product
      final productId = await productService.createProduct(
        barcode: _barcodeController.text.trim(),
        name: _nameController.text.trim(),
        canonicalIngredientId: _canonicalIngredientId!,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        category: _selectedCategory,
        suggestedUnit: _selectedUnit,
        imageUrl: imageUrl,
        contributorId: userId,
      );

      final product = await productService.getProductById(productId);
      
      if (product != null && mounted) {
        Logger.success('Product contributed successfully: $productId', 'ContributeProductScreen');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product contributed successfully! Thank you for your contribution.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
        context.pop(product);
      }
    } catch (e, stackTrace) {
      Logger.error('Error saving product', e, stackTrace, 'ContributeProductScreen');
      setState(() {
        _errorMessage = 'Error saving product: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          l10n?.contributeProduct ?? 'Contribute Product',
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
                        Icons.add_business,
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
                            'Contribute to Global Catalog',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Help others by adding product information',
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
              CustomTextField(
                label: 'Barcode (EAN/UPC)',
                controller: _barcodeController,
                prefixIcon: Icons.qr_code,
                keyboardType: TextInputType.number,
                enabled: widget.barcode != null, // Disable if pre-filled from scanner
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Barcode is required';
                  }
                  final barcode = value.trim();
                  if (!RegExp(r'^\d{8,14}$').hasMatch(barcode)) {
                    return 'Invalid barcode format (must be 8-14 digits)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Product name
              CustomTextField(
                label: 'Product Name *',
                controller: _nameController,
                prefixIcon: Icons.shopping_basket,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Product name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Brand (optional)
              CustomTextField(
                label: 'Brand (Optional)',
                controller: _brandController,
                prefixIcon: Icons.branding_watermark,
              ),
              const SizedBox(height: 16),

              // Category
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                    prefixIcon: Icon(Icons.category_outlined),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...PantryCategories.all.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
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

              // Suggested unit
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gray300),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedUnit,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Suggested Unit (Optional)',
                    prefixIcon: Icon(Icons.straighten),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...Units.all.map((unit) {
                      return DropdownMenuItem(
                        value: unit,
                        child: Text(unit),
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
              const SizedBox(height: 24),

              // Canonical ingredient section
              _buildSectionTitle('Map to Ingredient'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'Ingredient Name *',
                      controller: _ingredientNameController,
                      prefixIcon: Icons.restaurant,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingredient name is required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _findCanonicalIngredient,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Find'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ],
              ),
              if (_canonicalIngredientId != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Ingredient mapped: ${_ingredientNameController.text}',
                          style: const TextStyle(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Product photo
              _buildSectionTitle('Product Photo (Optional)'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedImage != null ? AppColors.primary : AppColors.gray300,
                      width: 2,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to add photo',
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

              // Save button
              CustomButton(
                text: 'Contribute Product',
                onPressed: _isLoading ? null : _saveProduct,
                isLoading: _isLoading,
                icon: Icons.save,
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
