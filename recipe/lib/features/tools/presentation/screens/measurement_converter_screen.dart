import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/standard_app_bar.dart';
import '../../../../core/utils/translations.dart';
import '../../../../core/constants/firebase_constants.dart';
import '../../../../services/measurement_converter_service.dart';

class MeasurementConverterScreen extends StatefulWidget {
  const MeasurementConverterScreen({super.key});

  @override
  State<MeasurementConverterScreen> createState() => _MeasurementConverterScreenState();
}

class _MeasurementConverterScreenState extends State<MeasurementConverterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _valueController = TextEditingController();
  String _fromUnit = Units.grams;
  String _toUnit = Units.kilograms;
  ConversionResult? _conversionResult;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Add listener for real-time conversion
    _valueController.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    _valueController.removeListener(_onValueChanged);
    _valueController.dispose();
    super.dispose();
  }

  void _onValueChanged() {
    // Auto-convert as user types (with debounce effect)
    final text = _valueController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _conversionResult = null;
        _errorMessage = null;
      });
      return;
    }

    final value = double.tryParse(text);
    if (value != null && value >= 0) {
      _performConversion(showErrors: false);
    } else {
      setState(() {
        _conversionResult = null;
        _errorMessage = null;
      });
    }
  }

  void _performConversion({bool showErrors = true}) {
    final text = _valueController.text.trim();

    if (text.isEmpty) {
      if (showErrors) {
        setState(() {
          _errorMessage = 'Por favor ingresa un valor';
          _conversionResult = null;
        });
      }
      return;
    }

    final value = double.tryParse(text);
    if (value == null) {
      if (showErrors) {
        setState(() {
          _errorMessage = 'Por favor ingresa un número válido';
          _conversionResult = null;
        });
      }
      return;
    }

    if (value < 0) {
      if (showErrors) {
        setState(() {
          _errorMessage = 'El valor debe ser positivo';
          _conversionResult = null;
        });
      }
      return;
    }

    // Check if conversion is possible
    if (!MeasurementConverterService.canConvert(_fromUnit, _toUnit)) {
      setState(() {
        _errorMessage = 'No se puede convertir entre estas unidades. Las unidades deben ser del mismo tipo (peso o volumen).';
        _conversionResult = null;
      });
      return;
    }

    // Perform conversion
    final result = MeasurementConverterService.convert(
      value: value,
      fromUnit: _fromUnit,
      toUnit: _toUnit,
    );

    setState(() {
      if (result != null) {
        _conversionResult = result;
        _errorMessage = null;
      } else {
        if (showErrors) {
          _errorMessage = 'Error al realizar la conversión';
        }
        _conversionResult = null;
      }
    });
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      // Re-run conversion with swapped units
      if (_valueController.text.isNotEmpty) {
        _performConversion(showErrors: false);
      }
    });
  }

  void _applyQuickConversion(double value, String fromUnit, String toUnit) {
    setState(() {
      _valueController.text = value.toString();
      _fromUnit = fromUnit;
      // Update to unit to be compatible
      final compatibleUnits = MeasurementConverterService.getCompatibleUnits(fromUnit);
      if (compatibleUnits.contains(toUnit)) {
        _toUnit = toUnit;
      } else if (compatibleUnits.isNotEmpty) {
        _toUnit = compatibleUnits.first;
      }
    });
    _performConversion(showErrors: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: StandardAppBar(
        title: 'Convertidor de Medidas',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Card with instructions
              Container(
                padding: const EdgeInsets.all(16),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Convertidor de Unidades',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Instrucciones:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildInstructionRow('1', 'Ingresa la cantidad a convertir'),
                    _buildInstructionRow('2', 'Selecciona la unidad de origen'),
                    _buildInstructionRow('3', 'Selecciona la unidad de destino'),
                    _buildInstructionRow('4', 'El resultado se muestra automáticamente'),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Quick Conversions
              _buildQuickConversionsSection(),
              const SizedBox(height: 24),

              // Value Input with clear label
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gray200.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Paso 1: Ingresa el valor',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gray300,
                        ),
                        filled: true,
                        fillColor: AppColors.gray50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Ingresa un número (ej: 500, 1.5, 0.25)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Unit Selection Row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gray200.withOpacity(0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.compare_arrows_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Paso 2: Selecciona las unidades',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // From Unit
                    _buildUnitDropdown(
                      label: 'De:',
                      value: _fromUnit,
                      items: Units.all,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _fromUnit = value;
                            // Update compatible units for "to" dropdown
                            final compatibleUnits = MeasurementConverterService.getCompatibleUnits(value);
                            final compatibleEnglish = compatibleUnits
                                .where((u) => Units.all.contains(u))
                                .toList();
                            if (!compatibleEnglish.contains(_toUnit)) {
                              if (compatibleEnglish.isNotEmpty) {
                                _toUnit = compatibleEnglish.first;
                              }
                            }
                          });
                          _performConversion(showErrors: false);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Swap Button
                    Center(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _swapUnits,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.swap_vert_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // To Unit
                    _buildUnitDropdown(
                      label: 'A:',
                      value: _toUnit,
                      items: MeasurementConverterService.getCompatibleUnits(_fromUnit)
                          .where((unit) => Units.all.contains(unit))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _toUnit = value;
                          });
                          _performConversion(showErrors: false);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Result Display (always visible when there's a value)
              if (_conversionResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.15),
                        AppColors.success.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.4),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Resultado',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Conversion display
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // From value
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _valueController.text,
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Translations.translateUnit(_fromUnit),
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Icon(
                              Icons.arrow_downward_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            const SizedBox(height: 8),
                            // To value
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  _conversionResult!.formattedValue,
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  Translations.translateUnit(_conversionResult!.unit),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      if (_conversionResult!.note != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.lightbulb_outline_rounded,
                                size: 18,
                                color: AppColors.secondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _conversionResult!.note!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Error Display
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Unit Reference Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.gray200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Referencia de Equivalencias',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildConversionInfo(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickConversionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flash_on_rounded,
              color: AppColors.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Conversiones Rápidas',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildQuickConversionChip('1 taza → ml', 1, Units.cups, Units.milliliters),
              const SizedBox(width: 8),
              _buildQuickConversionChip('100g → oz', 100, Units.grams, Units.ounces),
              const SizedBox(width: 8),
              _buildQuickConversionChip('1 lb → g', 1, Units.pounds, Units.grams),
              const SizedBox(width: 8),
              _buildQuickConversionChip('500ml → tazas', 500, Units.milliliters, Units.cups),
              const SizedBox(width: 8),
              _buildQuickConversionChip('1 L → ml', 1, Units.liters, Units.milliliters),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickConversionChip(String label, double value, String fromUnit, String toUnit) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _applyQuickConversion(value, fromUnit, toUnit),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray200.withOpacity(0.5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnitDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.gray50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.gray200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                ),
                items: items.map((unit) {
                  return DropdownMenuItem(
                    value: unit,
                    child: Text(
                      Translations.translateUnit(unit),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConversionInfo() {
    if (_isWeightUnit(_fromUnit)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('1 kilogramo', '= 1000 gramos'),
          _buildInfoRow('1 libra', '= 453.6 gramos (16 onzas)'),
          _buildInfoRow('1 onza', '= 28.35 gramos'),
          const Divider(height: 16),
          _buildInfoRow('1 kilogramo', '≈ 2.2 libras'),
          _buildInfoRow('1 libra', '= 16 onzas'),
        ],
      );
    } else if (_isVolumeUnit(_fromUnit)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('1 litro', '= 1000 mililitros'),
          _buildInfoRow('1 taza', '= 236.6 mililitros'),
          _buildInfoRow('1 cucharada', '= 14.8 ml (3 cucharaditas)'),
          _buildInfoRow('1 cucharadita', '= 4.9 mililitros'),
          const Divider(height: 16),
          _buildInfoRow('1 galón', '= 3.785 litros (16 tazas)'),
          _buildInfoRow('1 pinta', '= 473.2 ml (2 tazas)'),
          _buildInfoRow('1 onza líquida', '= 29.6 mililitros'),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  bool _isWeightUnit(String unit) {
    return unit == Units.grams ||
           unit == Units.kilograms ||
           unit == Units.ounces ||
           unit == Units.pounds;
  }

  bool _isVolumeUnit(String unit) {
    return unit == Units.liters ||
           unit == Units.milliliters ||
           unit == Units.cups ||
           unit == Units.tablespoons ||
           unit == Units.teaspoons ||
           unit == Units.fluidOunces ||
           unit == Units.pints ||
           unit == Units.quarts ||
           unit == Units.gallons;
  }
}
