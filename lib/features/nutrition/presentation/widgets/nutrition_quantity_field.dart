import 'package:flutter/material.dart';

import '../../data/nutrition_quantity_suggester.dart';

class NutritionQuantityField extends StatefulWidget {
  final TextEditingController mealNameController;
  final TextEditingController quantityController;
  final InputDecoration decoration;
  final TextInputAction textInputAction;

  const NutritionQuantityField({
    super.key,
    required this.mealNameController,
    required this.quantityController,
    required this.decoration,
    this.textInputAction = TextInputAction.next,
  });

  @override
  State<NutritionQuantityField> createState() => _NutritionQuantityFieldState();
}

class _NutritionQuantityFieldState extends State<NutritionQuantityField> {
  String? _lastAppliedSuggestion;
  late bool _hasUserEditedQuantity;
  bool _isApplyingSuggestion = false;

  @override
  void initState() {
    super.initState();
    _hasUserEditedQuantity = widget.quantityController.text.trim().isNotEmpty;
    _attachListeners();
    _updateSuggestion();
  }

  @override
  void didUpdateWidget(covariant NutritionQuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mealNameController == widget.mealNameController &&
        oldWidget.quantityController == widget.quantityController) {
      return;
    }

    oldWidget.mealNameController.removeListener(_updateSuggestion);
    oldWidget.quantityController.removeListener(_handleQuantityChanged);
    _lastAppliedSuggestion = null;
    _hasUserEditedQuantity = widget.quantityController.text.trim().isNotEmpty;
    _attachListeners();
    _updateSuggestion();
  }

  @override
  void dispose() {
    widget.mealNameController.removeListener(_updateSuggestion);
    widget.quantityController.removeListener(_handleQuantityChanged);
    super.dispose();
  }

  void _attachListeners() {
    widget.mealNameController.addListener(_updateSuggestion);
    widget.quantityController.addListener(_handleQuantityChanged);
  }

  void _updateSuggestion() {
    if (_hasUserEditedQuantity) {
      return;
    }

    final currentQuantity = widget.quantityController.text;
    if (currentQuantity.isNotEmpty &&
        currentQuantity != _lastAppliedSuggestion) {
      _hasUserEditedQuantity = true;
      return;
    }

    final suggestion = NutritionQuantitySuggester.suggest(
      widget.mealNameController.text,
    );
    if (currentQuantity == (suggestion ?? '')) {
      _lastAppliedSuggestion = suggestion;
      return;
    }

    _isApplyingSuggestion = true;
    widget.quantityController.value = TextEditingValue(
      text: suggestion ?? '',
      selection: suggestion == null
          ? const TextSelection.collapsed(offset: 0)
          : TextSelection(baseOffset: 0, extentOffset: suggestion.length),
    );
    _isApplyingSuggestion = false;
    _lastAppliedSuggestion = suggestion;
  }

  void _handleQuantityChanged() {
    if (_isApplyingSuggestion) {
      return;
    }

    if (widget.quantityController.text.isEmpty &&
        widget.mealNameController.text.trim().isEmpty) {
      _hasUserEditedQuantity = false;
      _lastAppliedSuggestion = null;
    }
  }

  void _markQuantityAsUserEdited(String _) {
    _hasUserEditedQuantity = true;
    _lastAppliedSuggestion = null;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const ValueKey('manual-meal-quantity-field'),
      controller: widget.quantityController,
      textInputAction: widget.textInputAction,
      decoration: widget.decoration,
      onChanged: _markQuantityAsUserEdited,
    );
  }
}
