import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../providers/recipe_provider.dart';
import '../../../../providers/profile_provider.dart';
import '../../../../providers/pantry_provider.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../models/recipe_model.dart';
import '../../../../models/pantry_item_model.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/translations.dart';
import '../../../../services/recipe_recommendation_service.dart';
import '../../../../models/ingredient_price_model.dart';
import 'package:uuid/uuid.dart';

class RecipeAddScreen extends ConsumerStatefulWidget {
  final Recipe? recipe; // If provided, we're in edit mode

  const RecipeAddScreen({super.key, this.recipe});

  @override
  ConsumerState<RecipeAddScreen> createState() => _RecipeAddScreenState();
}

class _RecipeAddScreenState extends ConsumerState<RecipeAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late TextEditingController _titleController;
  late TextEditingController _cookTimeController;
  late TextEditingController _sourceController;
  late TextEditingController _yieldValueController;
  late TextEditingController _portionSizeController;
  String _yieldUnit = YieldUnits.grams; // Default for dropdown
  List<RecipeIngredient> _ingredients = [];
  List<String> _instructions = [];
  File? _imageFile;
  Uint8List? _imageBytes; // For web platform
  String? _existingImageUrl; // For edit mode
  final ImagePicker _imagePicker = ImagePicker();
  bool get _isEditMode => widget.recipe != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final recipe = widget.recipe!;
      _titleController = TextEditingController(text: recipe.title);
      _cookTimeController = TextEditingController(text: recipe.cookTime.toString());
      _sourceController = TextEditingController(text: recipe.source ?? '');
      _yieldValueController = TextEditingController(
        text: recipe.yieldValue != null ? recipe.yieldValue.toString() : '',
      );
      _portionSizeController = TextEditingController(
        text: recipe.standardPortionSize != null ? recipe.standardPortionSize.toString() : '',
      );
      _yieldUnit = recipe.yieldUnit ?? YieldUnits.grams;
      _ingredients = List.from(recipe.ingredients);
      _instructions = List.from(recipe.instructions);
      _existingImageUrl = recipe.imageUrl;
    } else {
      _titleController = TextEditingController();
      _cookTimeController = TextEditingController();
      _sourceController = TextEditingController();
      _yieldValueController = TextEditingController();
      _portionSizeController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cookTimeController.dispose();
    _sourceController.dispose();
    _yieldValueController.dispose();
    _portionSizeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        // On web, don't compress too much as it can corrupt the image
        imageQuality: kIsWeb ? 100 : 85, // Use 100% quality on web to prevent corruption
      );
      if (image != null) {
        if (kIsWeb) {
          // On web, we need to read bytes instead of using File
          final bytes = await image.readAsBytes();
          
          // Validate that we got valid image bytes
          if (bytes.isEmpty) {
            throw Exception('Los datos de la imagen están vacíos');
          }
          
          // Check minimum size (at least 100 bytes for a valid image)
          if (bytes.length < 100) {
            throw Exception('El archivo de imagen es demasiado pequeño o está corrupto');
          }
          
          // Validate image format by checking magic bytes
          if (!_isValidImageFormat(bytes)) {
            throw Exception('El formato de la imagen no es válido. Por favor selecciona una imagen JPEG, PNG, GIF o WebP válida.');
          }
          
          if (mounted) {
            setState(() {
              _imageBytes = bytes;
              _imageFile = null;
              _existingImageUrl = null;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _imageFile = File(image.path);
              _imageBytes = null;
              _existingImageUrl = null; // Clear existing URL when new image is selected
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _imageFile = null;
      _imageBytes = null;
      _existingImageUrl = null;
    });
  }

  /// Validate image format by checking magic bytes (file signature)
  bool _isValidImageFormat(Uint8List bytes) {
    if (bytes.length < 4) return false;
    
    // Check for JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
      return true;
    }
    
    // Check for PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
      return true;
    }
    
    // Check for GIF: 47 49 46 38
    if (bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38) {
      return true;
    }
    
    // Check for WebP: RIFF...WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) {
      return true;
    }
    
    return false;
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => _AddIngredientDialog(
        ref: ref,
        onSave: (ingredient) {
          setState(() {
            _ingredients.add(ingredient);
          });
        },
      ),
    );
  }

  void _editIngredient(int index) {
    final ingredient = _ingredients[index];
    showDialog(
      context: context,
      builder: (context) => _AddIngredientDialog(
        ref: ref,
        initialIngredient: ingredient,
        onSave: (updatedIngredient) {
          setState(() {
            _ingredients[index] = updatedIngredient;
          });
        },
      ),
    );
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  void _addInstruction() {
    showDialog(
      context: context,
      builder: (context) => _AddInstructionDialog(
        onSave: (instruction) {
          setState(() {
            _instructions.add(instruction);
          });
        },
      ),
    );
  }

  void _editInstruction(int index) {
    final instruction = _instructions[index];
    showDialog(
      context: context,
      builder: (context) => _AddInstructionDialog(
        initialInstruction: instruction,
        onSave: (updatedInstruction) {
          setState(() {
            _instructions[index] = updatedInstruction;
          });
        },
      ),
    );
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructions.removeAt(index);
    });
  }


  Future<void> _saveRecipe() async {
    Logger.info('Save recipe button clicked', 'RecipeAddScreen');
    
    if (!_formKey.currentState!.validate()) {
      Logger.warning('Form validation failed', 'RecipeAddScreen');
      
      // Show a helpful message to the user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor completa todos los campos requeridos correctamente'),
            backgroundColor: AppColors.error,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
      // Try to identify which field failed
      final titleError = Validators.validateMinLength(_titleController.text, 3, 'Título');
      final cookTimeError = Validators.validatePositiveNumber(_cookTimeController.text, 'Tiempo de cocción');
      
      if (titleError != null) {
        Logger.warning('Title validation failed: $titleError', 'RecipeAddScreen');
        // Scroll to top to show title field error
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else if (cookTimeError != null) {
        Logger.warning('Cook time validation failed: $cookTimeError', 'RecipeAddScreen');
        // Scroll to show cook time field error (approximately 200px down)
        _scrollController.animateTo(
          200,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      
      return;
    }
    
    Logger.info('Form validation passed', 'RecipeAddScreen');

    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor agrega al menos un ingrediente'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_instructions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor agrega al menos una instrucción'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay usuario conectado'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final cookTime = int.tryParse(_cookTimeController.text) ?? 0;
    final now = DateTime.now();

    try {
      // Get image data based on platform
      final imageData = kIsWeb ? _imageBytes : _imageFile;
      
      // Validate image data if present
      if (imageData != null) {
        if (kIsWeb) {
          if (_imageBytes == null || _imageBytes!.isEmpty) {
            Logger.warning('Image bytes are null or empty', 'RecipeAddScreen');
          }
        } else {
          if (_imageFile == null || !_imageFile!.existsSync()) {
            Logger.warning('Image file is null or does not exist', 'RecipeAddScreen');
          }
        }
      }
      
      Logger.info(
        'Saving recipe - hasImage: ${imageData != null}, isWeb: $kIsWeb, imageFile: ${_imageFile != null}, imageBytes: ${_imageBytes != null}, imageBytesLength: ${_imageBytes?.length ?? 0}',
        'RecipeAddScreen',
      );
      
      final yieldValue = _yieldValueController.text.trim().isEmpty
          ? null
          : double.tryParse(_yieldValueController.text.trim());
      final portionSize = _portionSizeController.text.trim().isEmpty
          ? null
          : double.tryParse(_portionSizeController.text.trim());
      final yieldUnit = _yieldValueController.text.trim().isEmpty ? null : _yieldUnit;

      if (_isEditMode) {
        // Update existing recipe
        final updatedRecipe = widget.recipe!.copyWith(
          title: _titleController.text.trim(),
          ingredients: _ingredients,
          instructions: _instructions,
          cookTime: cookTime,
          source: _sourceController.text.trim().isEmpty
              ? null
              : _sourceController.text.trim(),
          imageUrl: imageData == null ? _existingImageUrl : null, // Keep existing if no new image
          yieldValue: yieldValue,
          yieldUnit: yieldUnit,
          standardPortionSize: portionSize,
          updatedAt: now,
        );

        await ref.read(recipeControllerProvider.notifier).updateRecipe(
              updatedRecipe,
              imageData: imageData,
              oldImageUrl: imageData != null ? _existingImageUrl : null,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Receta actualizada exitosamente'),
              backgroundColor: AppColors.success,
            ),
          );
          context.pop();
        }
      } else {
        // Create new recipe
        final recipe = Recipe(
          id: const Uuid().v4(),
          title: _titleController.text.trim(),
          ingredients: _ingredients,
          instructions: _instructions,
          cookTime: cookTime,
          source: _sourceController.text.trim().isEmpty
              ? null
              : _sourceController.text.trim(),
          authorId: userId,
          imageUrl: null, // Will be set after image upload
          yieldValue: yieldValue,
          yieldUnit: yieldUnit,
          standardPortionSize: portionSize,
          createdAt: now,
          updatedAt: now,
        );

        try {
          // Add timeout wrapper to ensure we don't hang forever
          await Future.any([
            ref.read(recipeControllerProvider.notifier).addRecipe(
                  recipe,
                  imageData: imageData,
                ),
            Future.delayed(const Duration(seconds: 60)).then((_) {
              throw Exception('Recipe save operation timed out after 60 seconds');
            }),
          ]);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Receta agregada exitosamente'),
                backgroundColor: AppColors.success,
              ),
            );
            context.pop();
          }
        } catch (e, stackTrace) {
          Logger.error('Failed to save recipe', e, stackTrace, 'RecipeAddScreen');
          
          // Ensure state is reset even if there's an error
          // The controller should handle this, but let's be safe
          try {
            // Check if state is stuck in loading
            final currentState = ref.read(recipeControllerProvider);
            if (currentState.isLoading) {
              Logger.warning('State stuck in loading, this should not happen', 'RecipeAddScreen');
            }
          } catch (_) {
            // Ignore errors when checking state
          }
          
          if (mounted) {
            final errorMessage = e.toString();
            String userMessage;
            
            if (errorMessage.contains('image') || errorMessage.contains('upload') || errorMessage.contains('Storage')) {
              userMessage = 'Receta guardada, pero falló la carga de la imagen. La receta se creó sin imagen.';
            } else {
              userMessage = 'Error al guardar receta: ${errorMessage.length > 100 ? errorMessage.substring(0, 100) + "..." : errorMessage}';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(userMessage),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 5),
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
    } catch (e, stackTrace) {
      Logger.error('Failed to save recipe (outer catch)', e, stackTrace, 'RecipeAddScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la receta: ${e.toString()}'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(recipeControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Editar Receta' : 'Agregar Receta',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card with Progress Indicator
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gray200, width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.restaurant_menu_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEditMode ? 'Editar Receta' : 'Crear Nueva Receta',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isEditMode
                                    ? 'Actualiza los detalles de tu receta'
                                    : 'Comparte tu obra maestra culinaria',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Progress indicator
                    Row(
                      children: [
                        _buildProgressStep('Básico', true),
                        _buildProgressLine(true),
                        _buildProgressStep('Detalles', _ingredients.isNotEmpty || _instructions.isNotEmpty),
                        _buildProgressLine(_ingredients.isNotEmpty || _instructions.isNotEmpty),
                        _buildProgressStep('Revisar', _ingredients.isNotEmpty && _instructions.isNotEmpty),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Recipe Details
              _buildSectionTitle('Detalles de la Receta'),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gray200.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CustomTextField(
                      label: 'Título de la Receta',
                      controller: _titleController,
                      prefixIcon: Icons.title_rounded,
                      validator: (value) => Validators.validateMinLength(value, 3, 'Título'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Tiempo de Cocción (minutos)',
                      controller: _cookTimeController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.timer_outlined,
                      hint: 'ej., 30',
                      validator: (value) => Validators.validatePositiveNumber(value, 'Tiempo de cocción'),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      label: 'Fuente (Opcional)',
                      controller: _sourceController,
                      prefixIcon: Icons.link_rounded,
                      hint: 'ej., URL del sitio web o nombre del libro de cocina',
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          // Check if it looks like a URL
                          if (value.trim().startsWith('http://') || 
                              value.trim().startsWith('https://')) {
                            return Validators.validateUrl(value);
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Yield and portion (Phase 2)
                    Text(
                      'Rendimiento y porciones (opcional)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: CustomTextField(
                            label: 'Rendimiento total',
                            controller: _yieldValueController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            prefixIcon: Icons.scale_outlined,
                            hint: 'ej. 500',
                            validator: (value) {
                              if (value != null && value.trim().isNotEmpty) {
                                return Validators.validateYieldValue(value);
                              }
                              return null;
                            },
                            textInputAction: TextInputAction.next,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.gray300),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: YieldUnits.all.contains(_yieldUnit) ? _yieldUnit : YieldUnits.grams,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Unidad',
                                prefixIcon: Icon(Icons.straighten),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              items: YieldUnits.all.map((unit) {
                                final translated = Translations.translateUnit(unit);
                                return DropdownMenuItem(
                                  value: unit,
                                  child: Text(translated, overflow: TextOverflow.ellipsis),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) setState(() => _yieldUnit = value);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Cantidad por porción',
                      controller: _portionSizeController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.restaurant_outlined,
                      hint: 'ej. 125 (en la misma unidad del rendimiento)',
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          final totalYield = double.tryParse(_yieldValueController.text.trim());
                          return Validators.validatePortionSize(value, totalYield);
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recipe Image Section
              _buildSectionTitle('Imagen de la Receta (Opcional)'),
              const SizedBox(height: 16),
              _buildImagePickerSection(),

              const SizedBox(height: 24),

              // Ingredients Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Ingredientes'),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _addIngredient,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 20, color: AppColors.primary),
                            const SizedBox(width: 6),
                            const Text(
                              'Agregar Ingrediente',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_ingredients.isNotEmpty)
                ..._ingredients.asMap().entries.map((entry) {
                  final index = entry.key;
                  final ingredient = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray200, width: 1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _editIngredient(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.primaryLight,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ingredient.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondary.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '${ingredient.quantity} ${Translations.translateUnit(ingredient.unit)}',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _editIngredient(index),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _removeIngredient(index),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete_rounded,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),

              // Instructions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Instrucciones'),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _addInstruction,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.secondary.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded, size: 20, color: AppColors.secondary),
                            const SizedBox(width: 6),
                            const Text(
                              'Agregar Paso',
                              style: TextStyle(
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_instructions.isNotEmpty)
                ..._instructions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final instruction = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray200, width: 1),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _editInstruction(index),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.secondary,
                                      AppColors.secondaryLight,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.secondary.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  instruction,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.textPrimary,
                                    height: 1.6,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _editInstruction(index),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _removeInstruction(index),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.delete_rounded,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 32),

              // Save Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: isLoading 
                        ? () {
                            Logger.warning('Button tapped but isLoading is true', 'RecipeAddScreen');
                          }
                        : () {
                            Logger.info('Button tapped, calling _saveRecipe', 'RecipeAddScreen');
                            _saveRecipe();
                          },
                        child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isLoading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else ...[
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              _isEditMode ? 'Actualizar Receta' : 'Guardar Receta',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStep(String label, bool isCompleted) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.primary : AppColors.gray300,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      label.isNotEmpty ? label[0] : '?',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isCompleted ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 3,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.primary : AppColors.gray300,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }


  Widget _buildImagePickerSection() {
    final hasImage = _imageFile != null || _imageBytes != null || _existingImageUrl != null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gray200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray200.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasImage)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                color: AppColors.gray50,
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: _imageBytes != null
                        ? Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          )
                        : _imageFile != null
                            ? Image.file(
                                _imageFile!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 200,
                              )
                            : _existingImageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: _existingImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: 200,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.gray100,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: AppColors.gray100,
                                      child: const Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                        size: 48,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        onTap: _removeImage,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (!hasImage)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.gray50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.gray200,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.image_outlined,
                          size: 64,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay imagen seleccionada',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega una foto para que tu receta destaque',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: hasImage ? 16 : 0),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library, size: 20),
                        label: Text(hasImage ? 'Cambiar Imagen' : 'Seleccionar de la Galería'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddIngredientDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final RecipeIngredient? initialIngredient;
  final Function(RecipeIngredient) onSave;

  const _AddIngredientDialog({
    required this.ref,
    this.initialIngredient,
    required this.onSave,
  });

  @override
  ConsumerState<_AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends ConsumerState<_AddIngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _unitController;
  late TextEditingController _unitPriceController;
  String _priceUnit = Units.pieces; // MXN per g/kg/ml/L/pc
  PricingType _pricingType = PricingType.perUnit;
  late TextEditingController _packageSizeController;
  late TextEditingController _amazonLinkController;
  late TextEditingController _walmartLinkController;
  bool _linksInherited = false;
  String? _inheritedFromPantry;
  bool _priceLoading = false;

  static const _priceUnitOptions = [Units.grams, Units.kilograms, Units.milliliters, Units.liters, Units.pieces];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialIngredient?.name ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.initialIngredient?.quantity.toString() ?? '1',
    );
    _unitController = TextEditingController(
      text: widget.initialIngredient?.unit ?? 'pieces',
    );
    _priceUnit = widget.initialIngredient != null &&
            _priceUnitOptions.contains(widget.initialIngredient!.unit)
        ? widget.initialIngredient!.unit
        : Units.pieces;
    _unitPriceController = TextEditingController();
    _packageSizeController = TextEditingController();
    _amazonLinkController = TextEditingController(
      text: widget.initialIngredient?.amazonLink ?? '',
    );
    _walmartLinkController = TextEditingController(
      text: widget.initialIngredient?.walmartLink ?? '',
    );
    // Pre-load existing price when editing an ingredient
    final canonicalId = widget.initialIngredient?.canonicalIngredientId;
    if (canonicalId != null && canonicalId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingPrice(canonicalId));
    }
  }

  Future<void> _loadExistingPrice(String canonicalId) async {
    final userId = widget.ref.read(currentUserIdProvider);
    if (userId == null) return;
    if (mounted) setState(() => _priceLoading = true);
    try {
      final priceService = widget.ref.read(ingredientPriceServiceProvider);
      final price = await priceService.getUserIngredientPrice(canonicalId, userId);
      if (mounted) {
        final effectivePrice = price?.userOverridePrice ?? price?.averagePrice;
        if (effectivePrice != null && effectivePrice > 0) {
          _unitPriceController.text = effectivePrice.toStringAsFixed(2);
        }
        if (price?.priceUnit != null && _priceUnitOptions.contains(price!.priceUnit)) {
          _priceUnit = price.priceUnit;
        }
        // Restore pricing type and package size
        _pricingType = price?.pricingType ?? PricingType.perUnit;
        if (price?.packageSize != null && price!.packageSize! > 0) {
          _packageSizeController.text = price.packageSize!.toStringAsFixed(0);
        }
        setState(() {});
      }
    } catch (e) {
      Logger.warning('Failed to load existing ingredient price', 'AddIngredientDialog');
    } finally {
      if (mounted) setState(() => _priceLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _unitPriceController.dispose();
    _packageSizeController.dispose();
    _amazonLinkController.dispose();
    _walmartLinkController.dispose();
    super.dispose();
  }

  /// Look up pantry item by ingredient name and inherit retailer links
  void _lookupAndInheritFromPantry() {
    final pantryAsync = ref.read(pantryItemsStreamProvider);
    pantryAsync.whenData((pantryItems) {
      final ingredientName = _nameController.text.trim().toLowerCase();
      if (ingredientName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primero ingresa el nombre del ingrediente'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      // Find matching pantry item
      final matchingItem = pantryItems.firstWhere(
        (item) => item.name.toLowerCase().contains(ingredientName) ||
            ingredientName.contains(item.name.toLowerCase()),
        orElse: () => PantryItem(
          id: '',
          name: '',
          quantity: 0,
          unit: '',
          category: '',
          addedAt: DateTime.now(),
        ),
      );

      if (matchingItem.id.isNotEmpty) {
        setState(() {
          // Inherit retailer links from pantry item
          if (matchingItem.amazonUrl != null && matchingItem.amazonUrl!.isNotEmpty) {
            _amazonLinkController.text = matchingItem.amazonUrl!;
          }
          if (matchingItem.walmartUrl != null && matchingItem.walmartUrl!.isNotEmpty) {
            _walmartLinkController.text = matchingItem.walmartUrl!;
          }
          _linksInherited = true;
          _inheritedFromPantry = matchingItem.name;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enlaces heredados de "${matchingItem.name}" en tu despensa'),
            backgroundColor: AppColors.success,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró este ingrediente en tu despensa'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Format ingredient name consistently for storage
    final formattedName = RecipeRecommendationService.formatIngredientNameForStorage(
      _nameController.text.trim(),
    );

    // Resolve/create canonical ingredient for price sync
    String? canonicalId;
    final canonicalService = widget.ref.read(canonicalIngredientServiceProvider);
    canonicalId = await canonicalService.createOrGetCanonicalIngredient(
      name: formattedName,
      defaultUnit: _unitController.text.trim(),
    );

    // Save unit price if provided (for Recipe/Shopping List cost)
    final userId = widget.ref.read(currentUserIdProvider);
    final priceText = _unitPriceController.text.trim();
    final unitPrice = priceText.isEmpty ? null : double.tryParse(priceText);
    if (userId != null && canonicalId.isNotEmpty && unitPrice != null && unitPrice > 0) {
      try {
        // Always use perPackage pricing: product price / product size
        // If user doesn't enter a size, default to 1 (same as per-unit)
        final packageSize = double.tryParse(_packageSizeController.text.trim()) ?? 1.0;
        await widget.ref.read(ingredientPriceServiceProvider).setUserIngredientPrice(
          userId: userId,
          canonicalIngredientId: canonicalId,
          unitPrice: unitPrice,
          priceUnit: _priceUnit,
          pricingType: PricingType.perPackage,
          packageSize: packageSize,
          packageUnit: _priceUnit,
        );
        // Bump price version so recipe cost widget re-fetches
        widget.ref.read(priceVersionProvider.notifier).state++;
      } catch (_) {
        // Non-critical - ingredient still saves
      }
    }

    final ingredient = RecipeIngredient(
      name: formattedName,
      canonicalIngredientId: canonicalId,
      quantity: double.tryParse(_quantityController.text) ?? 1.0,
      unit: _unitController.text.trim(),
      amazonLink: _amazonLinkController.text.trim().isEmpty
          ? null
          : _amazonLinkController.text.trim(),
      walmartLink: _walmartLinkController.text.trim().isEmpty
          ? null
          : _walmartLinkController.text.trim(),
    );

    if (mounted) {
      widget.onSave(ingredient);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(widget.initialIngredient == null
          ? 'Agregar Ingrediente'
          : 'Editar Ingrediente'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Nombre del Ingrediente',
                controller: _nameController,
                prefixIcon: Icons.shopping_basket_outlined,
                validator: Validators.validateItemName,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: CustomTextField(
                      label: 'Cantidad',
                      controller: _quantityController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.numbers,
                      validator: (value) =>
                          Validators.validatePositiveNumber(value, 'Cantidad'),
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
                          prefixIcon: Icon(Icons.straighten, size: 20),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                        items: Units.all.map((unit) {
                          final translatedUnit = Translations.translateUnit(unit);
                          return DropdownMenuItem(
                            value: unit,
                            child: Text(translatedUnit, overflow: TextOverflow.ellipsis),
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
              const SizedBox(height: 20),
              // Product Price (for recipe cost calculation)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Precio del producto (opcional)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa el precio y tamaño del producto que compraste. El costo se calcula automáticamente.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    if (_priceLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else ...[
                      // Row 1: Product price
                      CustomTextField(
                        label: 'Precio del producto (MXN)',
                        controller: _unitPriceController,
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        prefixIcon: Icons.payments_outlined,
                        hint: 'ej. 78 (lo que pagaste)',
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            return Validators.validatePositiveNumber(value, 'Precio');
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      // Row 2: Product size + unit
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: CustomTextField(
                              label: 'Tamaño del producto',
                              controller: _packageSizeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              prefixIcon: Icons.inventory_2_outlined,
                              hint: 'ej. 500',
                              validator: (value) {
                                if (value != null && value.trim().isNotEmpty) {
                                  return Validators.validatePositiveNumber(value, 'Tamaño');
                                }
                                return null;
                              },
                              textInputAction: TextInputAction.next,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.gray300),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _priceUnitOptions.contains(_priceUnit) ? _priceUnit : Units.pieces,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Unidad',
                                  prefixIcon: Icon(Icons.straighten, size: 20),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                ),
                                items: _priceUnitOptions.map((u) {
                                  return DropdownMenuItem(
                                    value: u,
                                    child: Text(Translations.translateUnit(u), overflow: TextOverflow.ellipsis),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setState(() => _priceUnit = v);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ej: Mayonesa de 500g a \$78 → si usas 100g, costo = \$15.60',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
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
                        Expanded(
                          child: Text(
                            'Enlaces de Compra (Opcional)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        // Button to inherit links from pantry
                        TextButton.icon(
                          onPressed: _lookupAndInheritFromPantry,
                          icon: Icon(
                            Icons.download_outlined,
                            size: 16,
                            color: AppColors.secondary,
                          ),
                          label: Text(
                            'Usar de Despensa',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.secondary,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agrega enlaces directos para comprar este ingrediente',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_linksInherited && _inheritedFromPantry != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Heredado de "$_inheritedFromPantry"',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Amazon Link
              TextFormField(
                controller: _amazonLinkController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Enlace de Amazon',
                  hintText: 'https://amazon.com/...',
                  helperText: 'Opcional - Deja vacío para generar automáticamente',
                  filled: true,
                  fillColor: AppColors.gray50,
                  prefixIcon: Icon(
                    Icons.shopping_bag_outlined,
                    color: const Color(0xFFFF9900),
                  ),
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
              ),
              const SizedBox(height: 16),
              // Walmart Link
              TextFormField(
                controller: _walmartLinkController,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'Enlace de Walmart',
                  hintText: 'https://walmart.com/...',
                  helperText: 'Opcional - Deja vacío para generar automáticamente',
                  filled: true,
                  fillColor: AppColors.gray50,
                  prefixIcon: Icon(
                    Icons.store_outlined,
                    color: const Color(0xFF0071CE),
                  ),
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
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

class _AddInstructionDialog extends StatefulWidget {
  final String? initialInstruction;
  final Function(String) onSave;

  const _AddInstructionDialog({
    this.initialInstruction,
    required this.onSave,
  });

  @override
  State<_AddInstructionDialog> createState() => _AddInstructionDialogState();
}

class _AddInstructionDialogState extends State<_AddInstructionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _instructionController;

  @override
  void initState() {
    super.initState();
    _instructionController = TextEditingController(
      text: widget.initialInstruction ?? '',
    );
  }

  @override
  void dispose() {
    _instructionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    widget.onSave(_instructionController.text.trim());
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final dialogWidth = isTablet ? 500.0 : screenWidth * 0.9;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: dialogWidth,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, isTablet ? 20 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.secondary.withOpacity(0.1),
                    AppColors.secondary.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.initialInstruction == null
                          ? Icons.add_rounded
                          : Icons.edit_rounded,
                      color: AppColors.secondary,
                      size: isTablet ? 28 : 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.initialInstruction == null
                              ? 'Agregar Paso de Instrucción'
                              : 'Editar Paso de Instrucción',
                          style: TextStyle(
                            fontSize: isTablet ? 22 : 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.initialInstruction == null
                              ? 'Agrega un nuevo paso a tu receta'
                              : 'Actualiza este paso de instrucción',
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isTablet ? 28 : 24),
                child: Form(
                  key: _formKey,
                  child: CustomTextField(
                    label: 'Instrucción',
                    controller: _instructionController,
                    prefixIcon: Icons.list_alt_rounded,
                    maxLines: isTablet ? 6 : 5,
                    keyboardType: TextInputType.multiline,
                    validator: (value) => Validators.validateMinLength(value, 5, 'Instrucción'),
                    textInputAction: TextInputAction.newline,
                    hint: 'Ingresa la instrucción paso a paso...',
                  ),
                ),
              ),
            ),
            // Actions
            Container(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 28 : 24,
                16,
                isTablet ? 28 : 24,
                isTablet ? 28 : 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.gray50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 20,
                        vertical: isTablet ? 14 : 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.secondary,
                          AppColors.secondaryDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _save,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 28 : 24,
                            vertical: isTablet ? 14 : 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Guardar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

