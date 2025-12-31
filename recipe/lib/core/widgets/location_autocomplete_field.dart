import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../data/countries_list.dart';

/// Location autocomplete field with country suggestions and autocorrect
class LocationAutocompleteField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Function(String)? onChanged;

  const LocationAutocompleteField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
  });

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final FocusNode _focusNode = FocusNode();
  bool _showSuggestions = false;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    if (text.isNotEmpty && _focusNode.hasFocus) {
      // Get suggestions based on raw input
      final suggestions = CountriesList.getSuggestions(text);

      // Also check if the autocorrected text would match differently
      final corrected = CountriesList.autocorrect(text);
      if (corrected != text && corrected.isNotEmpty) {
        final correctedSuggestions = CountriesList.getSuggestions(corrected);
        // Add corrected suggestions if they're different
        for (final suggestion in correctedSuggestions) {
          if (!suggestions.contains(suggestion)) {
            suggestions.add(suggestion);
          }
        }
      }

      setState(() {
        _suggestions = suggestions.take(10).toList();
        _showSuggestions = _suggestions.isNotEmpty;
      });
    } else {
      setState(() {
        _showSuggestions = false;
      });
    }
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      setState(() {
        _showSuggestions = false;
      });
      // Auto-correct when losing focus
      _autocorrect();
    }
  }

  void _autocorrect() {
    final text = widget.controller.text;
    if (text.isNotEmpty) {
      final corrected = CountriesList.autocorrect(text);
      if (corrected != text) {
        widget.controller.text = corrected;
        widget.onChanged?.call(corrected);
      }
    }
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.onChanged?.call(suggestion);
    setState(() {
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            enabled: widget.enabled,
            focusNode: _focusNode,
            onChanged: (value) {
              widget.onChanged?.call(value);
              _onTextChanged();
            },
            onEditingComplete: () {
              _autocorrect();
              _focusNode.unfocus();
            },
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.hint ?? widget.label,
              hintStyle: TextStyle(
                color: AppColors.gray400,
                fontSize: 16,
              ),
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
              filled: true,
              fillColor: Colors.white,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: AppColors.primary, size: 22)
                  : null,
              suffixIcon: widget.suffixIcon,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
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
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.gray200, width: 1.5),
              ),
            ),
          ),
        ),
        // Suggestions dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppColors.gray200,
                width: 1,
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final suggestion = _suggestions[index];
                return InkWell(
                  onTap: () => _selectSuggestion(suggestion),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}



