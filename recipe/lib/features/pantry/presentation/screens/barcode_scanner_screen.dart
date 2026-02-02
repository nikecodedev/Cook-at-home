import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../models/product_model.dart';

/// Barcode scanner screen for scanning product barcodes (EAN/UPC)
/// Flow:
/// 1. Scan barcode
/// 2. If product exists → return product for autofill
/// 3. If not → navigate to contribute product screen
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  late MobileScannerController _controller;
  bool _isProcessing = false;
  String? _lastScannedBarcode;
  String? _errorMessage;
  bool _torchEnabled = false;

  @override
  void initState() {
    super.initState();
    // Configure controller for optimal barcode detection
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
      // Enable all common product barcode formats
      formats: [
        BarcodeFormat.ean8,
        BarcodeFormat.ean13,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.codabar,
        BarcodeFormat.itf,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Toggle flashlight
  void _toggleTorch() async {
    try {
      await _controller.toggleTorch();
      setState(() {
        _torchEnabled = !_torchEnabled;
      });
    } catch (e) {
      Logger.error('Error toggling torch', e, null, 'BarcodeScannerScreen');
    }
  }

  /// Handle barcode detection
  Future<void> _handleBarcode(BarcodeCapture barcodeCapture) async {
    if (_isProcessing) return;

    if (barcodeCapture.barcodes.isEmpty) return;
    final barcode = barcodeCapture.barcodes.first;
    if (barcode.rawValue == null || barcode.rawValue!.isEmpty) return;

    final barcodeValue = barcode.rawValue!.trim();
    
    // Prevent duplicate processing of same barcode
    if (_lastScannedBarcode == barcodeValue) return;
    _lastScannedBarcode = barcodeValue;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      Logger.info('Barcode scanned: $barcodeValue', 'BarcodeScannerScreen');

      // Validate barcode format (EAN/UPC should be numeric, 8-14 digits)
      if (!_isValidBarcode(barcodeValue)) {
        setState(() {
          _errorMessage = 'Formato de código de barras inválido. Por favor escanea un código EAN/UPC válido.';
          _isProcessing = false;
        });
        return;
      }

      // Check if product exists
      final productService = ref.read(productServiceProvider);
      final product = await productService.getProductByBarcode(barcodeValue);

      if (product != null) {
        // Product exists - return it for autofill
        Logger.success('Product found: ${product.name}', 'BarcodeScannerScreen');
        if (mounted) {
          context.pop(product);
        }
      } else {
        // Product doesn't exist - navigate to contribute flow
        Logger.info('Product not found, navigating to contribute screen', 'BarcodeScannerScreen');
        if (mounted) {
          final result = await context.push<Product?>(
            '${Routes.contributeProduct}?barcode=$barcodeValue',
          );
          if (result != null && mounted) {
            // Product was contributed, return it
            context.pop(result);
          } else {
            // User cancelled, reset processing state
            setState(() {
              _isProcessing = false;
              _lastScannedBarcode = null;
            });
          }
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Error processing barcode', e, stackTrace, 'BarcodeScannerScreen');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al escanear: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }

  /// Validate barcode format (EAN/UPC)
  bool _isValidBarcode(String barcode) {
    // EAN/UPC barcodes are numeric and typically 8, 12, or 13 digits
    // Some can be 14 digits (EAN-14)
    final numericOnly = RegExp(r'^\d+$');
    if (!numericOnly.hasMatch(barcode)) return false;
    
    final length = barcode.length;
    return length >= 8 && length <= 14;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Producto'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (mounted) {
              context.pop(); // Allow user to go back without scanning
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error de cámara: ${error.errorCode.name}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Verifica los permisos de cámara en la configuración',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          // Scanning area overlay
          Center(
            child: Container(
              width: 280,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.primary,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.primary, width: 5),
                          left: BorderSide(color: AppColors.primary, width: 5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.primary, width: 5),
                          right: BorderSide(color: AppColors.primary, width: 5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    left: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.primary, width: 5),
                          left: BorderSide(color: AppColors.primary, width: 5),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.primary, width: 5),
                          right: BorderSide(color: AppColors.primary, width: 5),
                        ),
                      ),
                    ),
                  ),
                  // Scanning line animation
                  Center(
                    child: Container(
                      width: 260,
                      height: 2,
                      color: AppColors.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Instructions overlay at top
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Escanear Producto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Coloca el código de barras dentro del recuadro para agregar el producto a tu despensa',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Escanea o escribe el nombre del producto',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Flash toggle button
          Positioned(
            top: 120,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: Icon(
                  _torchEnabled ? Icons.flash_on : Icons.flash_off,
                  color: _torchEnabled ? AppColors.warning : Colors.white,
                  size: 28,
                ),
                onPressed: _toggleTorch,
                tooltip: _torchEnabled ? 'Apagar flash' : 'Encender flash',
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Buscando producto...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          _errorMessage = null;
                          _lastScannedBarcode = null;
                          _isProcessing = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),

          // Bottom buttons
          Positioned(
            bottom: _errorMessage != null ? 100 : 20,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search product button (manual entry)
                ElevatedButton.icon(
                  onPressed: () => _showManualEntryDialog(),
                  icon: const Icon(Icons.search_rounded, size: 20),
                  label: const Text(
                    'Buscar producto',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 12),
                // Manual barcode entry
                OutlinedButton.icon(
                  onPressed: () => _showBarcodeEntryDialog(),
                  icon: const Icon(Icons.dialpad_rounded, size: 18),
                  label: const Text(
                    'Ingresar código manualmente',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.5), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Cancel button
                TextButton.icon(
                  onPressed: () {
                    if (mounted) {
                      context.pop(); // Close scanner and go back
                    }
                  },
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.8),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Show dialog for product search (by name)
  void _showManualEntryDialog() {
    final TextEditingController searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.search_rounded, color: AppColors.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Buscar Producto',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escribe el nombre del producto que deseas agregar',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: searchController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ej: Leche, Huevos, Arroz...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                prefixIcon: Icon(Icons.inventory_2_outlined, color: AppColors.primary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              autofocus: true,
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  Navigator.pop(dialogContext);
                  _navigateToAddProduct(value.trim());
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final productName = searchController.text.trim();
              Navigator.pop(dialogContext);
              if (productName.isNotEmpty) {
                _navigateToAddProduct(productName);
              }
            },
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Agregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to add product screen with pre-filled name
  void _navigateToAddProduct(String productName) {
    if (mounted) {
      // Navigate to pantry edit screen (no barcode, just name)
      context.pop(); // Close scanner first
      context.push(Routes.pantryEdit, extra: Product(
        id: '', // Will be generated
        barcode: '',
        name: productName,
        canonicalIngredientId: '', // Will be resolved later
        imageUrl: null,
        category: null,
        brand: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }
  }

  /// Show dialog for manual barcode entry
  void _showBarcodeEntryDialog() {
    final TextEditingController barcodeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.dialpad_rounded, color: AppColors.secondary, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Ingresar Código de Barras',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Escribe el código de barras del producto (8-14 dígitos)',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: barcodeController,
              keyboardType: TextInputType.number,
              maxLength: 14,
              decoration: InputDecoration(
                hintText: 'Ej: 7501234567890',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: AppColors.gray50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.secondary, width: 2),
                ),
                prefixIcon: Icon(Icons.qr_code, color: AppColors.secondary),
                counterText: '',
              ),
              autofocus: true,
              onSubmitted: (value) {
                final barcode = value.trim();
                Navigator.pop(dialogContext);
                if (barcode.isNotEmpty) {
                  _processManualBarcode(barcode);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final barcode = barcodeController.text.trim();
              Navigator.pop(dialogContext);
              if (barcode.isNotEmpty) {
                _processManualBarcode(barcode);
              }
            },
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('Buscar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  /// Process manually entered barcode
  Future<void> _processManualBarcode(String barcodeValue) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      Logger.info('Manual barcode entered: $barcodeValue', 'BarcodeScannerScreen');

      // Validate barcode format
      if (!_isValidBarcode(barcodeValue)) {
        setState(() {
          _errorMessage = 'Formato de código de barras inválido. Debe tener 8-14 dígitos numéricos.';
          _isProcessing = false;
        });
        return;
      }

      // Check if product exists
      final productService = ref.read(productServiceProvider);
      final product = await productService.getProductByBarcode(barcodeValue);

      if (product != null) {
        Logger.success('Product found: ${product.name}', 'BarcodeScannerScreen');
        if (mounted) {
          context.pop(product);
        }
      } else {
        Logger.info('Product not found, navigating to contribute screen', 'BarcodeScannerScreen');
        if (mounted) {
          final result = await context.push<Product?>(
            '${Routes.contributeProduct}?barcode=$barcodeValue',
          );
          if (result != null && mounted) {
            context.pop(result);
          } else {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Error processing manual barcode', e, stackTrace, 'BarcodeScannerScreen');
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al buscar: ${e.toString()}';
          _isProcessing = false;
        });
      }
    }
  }
}

