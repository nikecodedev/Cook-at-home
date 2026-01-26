import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../providers/phase2_providers.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../services/canonical_ingredient_service.dart';
import '../../../../core/utils/logger.dart';
import 'package:go_router/go_router.dart';

/// Barcode scanner screen for scanning product barcodes
class BarcodeScannerScreen extends ConsumerStatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  ConsumerState<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends ConsumerState<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture barcodeCapture) async {
    if (_isProcessing) return;

    if (barcodeCapture.barcodes.isEmpty) return;
    final barcode = barcodeCapture.barcodes.first;
    if (barcode.rawValue == null || barcode.rawValue!.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final barcodeValue = barcode.rawValue!;
      Logger.info('Barcode scanned: $barcodeValue', 'BarcodeScannerScreen');

      // Check if product exists
      final productService = ref.read(productServiceProvider);
      final product = await productService.getProductByBarcode(barcodeValue);

      if (product != null) {
        // Product exists - navigate to contribute or use product
        if (mounted) {
          context.pop(product);
        }
      } else {
        // Product doesn't exist - show contribute flow
        if (mounted) {
          _showContributeDialog(barcodeValue);
        }
      }
    } catch (e) {
      Logger.error('Error processing barcode', e, null, 'BarcodeScannerScreen');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scanning barcode: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showContributeDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)?.contributeProduct ?? 'Contribute Product'),
        content: Text('Product with barcode $barcode not found. Would you like to contribute it?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to contribute product screen
              // TODO: Implement contribute product screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contribute product feature coming soon')),
              );
            },
            child: Text(AppLocalizations.of(context)?.save ?? 'Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.scanBarcode ?? 'Scan Barcode'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleBarcode,
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

