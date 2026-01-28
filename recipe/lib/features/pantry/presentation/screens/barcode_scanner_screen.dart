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
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedBarcode;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          _errorMessage = 'Invalid barcode format. Please scan a valid EAN/UPC barcode.';
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
          _errorMessage = 'Error scanning barcode: ${e.toString()}';
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
        title: Text(l10n?.scanBarcode ?? 'Scan Barcode'),
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
          ),
          
          // Instructions overlay
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Position barcode within the frame',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Processing overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Processing barcode...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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

          // Close/Cancel button at bottom
          Positioned(
            bottom: _errorMessage != null ? 100 : 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                if (mounted) {
                  context.pop(); // Close scanner and go back
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.9),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                l10n?.cancel ?? 'Cancel',
                style: const TextStyle(
                  fontSize: 16,
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

