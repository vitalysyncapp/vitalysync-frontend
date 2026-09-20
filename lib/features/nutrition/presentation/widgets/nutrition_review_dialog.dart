import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:vitalysync/l10n/localized_text.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../data/nutrition_api.dart';

enum NutritionReviewAction { saved, retry }

Future<NutritionReviewAction?> showNutritionReviewDialog({
  required BuildContext context,
  required List<NutritionReviewItem> items,
  required String mealLabel,
  required Future<String?> Function() onConfirm,
}) {
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<NutritionReviewAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withValues(alpha: 0.48),
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) => SafeArea(
      child: NutritionReviewDialog(
        items: items,
        mealLabel: mealLabel,
        onConfirm: onConfirm,
      ),
    ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      if (reduceMotion) return child;
      final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: curved.drive(
            Tween(begin: const Offset(0, 0.035), end: Offset.zero),
          ),
          child: ScaleTransition(
            scale: curved.drive(Tween(begin: 0.96, end: 1.0)),
            child: child,
          ),
        ),
      );
    },
  );
}

class NutritionReviewDialog extends StatefulWidget {
  final List<NutritionReviewItem> items;
  final String mealLabel;

  /// Returns a message on failure, or null once the meal has been saved.
  final Future<String?> Function() onConfirm;

  const NutritionReviewDialog({
    super.key,
    required this.items,
    required this.mealLabel,
    required this.onConfirm,
  });

  @override
  State<NutritionReviewDialog> createState() => _NutritionReviewDialogState();
}

class _NutritionReviewDialogState extends State<NutritionReviewDialog> {
  bool _isSaving = false;
  String? _errorText;

  void _refresh() => setState(() => _errorText = null);

  Future<void> _save() async {
    if (_isSaving || widget.items.isEmpty) return;
    final invalidItem = widget.items.any(
      (item) =>
          item.foodName.trim().isEmpty ||
          item.servingUnit.trim().isEmpty ||
          !item.servingQty.isFinite ||
          item.servingQty <= 0 ||
          [
            item.calories,
            item.proteinG,
            item.carbsG,
            item.fatG,
          ].any((value) => !value.isFinite || value < 0),
    );
    if (invalidItem) {
      setState(() {
        _errorText =
            'Check food details: add a name, unit, positive quantity, and non-negative nutrition values.';
      });
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _errorText = null;
    });
    String? error;
    try {
      error = await widget.onConfirm();
    } catch (_) {
      error = 'Unable to save this meal. Please try again.';
    }
    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _errorText = error;
    });
    if (error == null) {
      // Rebuild PopScope before closing the successfully saved review.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(NutritionReviewAction.saved);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final compact = MediaQuery.sizeOf(context).width < 380;
    final padding = compact ? 16.0 : 24.0;
    final radius = BorderRadius.circular(28);

    return PopScope(
      canPop: !_isSaving,
      child: Dialog(
        key: const ValueKey('nutrition-review-dialog'),
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
        constraints: const BoxConstraints(maxWidth: 840, maxHeight: 780),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: 840,
              decoration: BoxDecoration(
                color: pageSurfaceColor(context),
                borderRadius: radius,
                border: Border.all(color: pageBorderColor(context)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.all(padding),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  accent.withValues(alpha: 0.16),
                                  const Color(
                                    0xFF5DB8F0,
                                  ).withValues(alpha: 0.06),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.auto_awesome_rounded,
                                    color: accent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      LocalizedText(
                                        widget.mealLabel,
                                        style: TextStyle(
                                          color: accent,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Semantics(
                                        header: true,
                                        child: LocalizedText(
                                          'Your meal, decoded',
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                                color: pagePrimaryTextColor(
                                                  context,
                                                ),
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: -0.5,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      LocalizedText(
                                        'Review your foods and portions before logging.',
                                        style: TextStyle(
                                          color: pageSecondaryTextColor(
                                            context,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Cancel review'.localizedCopy(
                                    context,
                                  ),
                                  onPressed: _isSaving
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(padding),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSummary(context),
                                const SizedBox(height: 24),
                                LocalizedText(
                                  'Identified foods (${widget.items.length})',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: pagePrimaryTextColor(context),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (widget.items.isEmpty)
                                  LocalizedText(
                                    'No foods to log. Try analyzing your meal again.',
                                    style: TextStyle(
                                      color: pageSecondaryTextColor(context),
                                    ),
                                  ),
                                for (final item in widget.items)
                                  _ReviewFoodCard(
                                    key: ObjectKey(item),
                                    item: item,
                                    enabled: !_isSaving,
                                    onChanged: _refresh,
                                    onRemove: () => setState(() {
                                      widget.items.remove(item);
                                      _errorText = null;
                                    }),
                                  ),
                                const SizedBox(height: 4),
                                LocalizedText(
                                  'Nutrition values are estimates. Tap a food to adjust its details.',
                                  style: TextStyle(
                                    color: pageSecondaryTextColor(context),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, color: pageBorderColor(context)),
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_errorText != null) ...[
                          Semantics(
                            liveRegion: true,
                            child: LocalizedText(
                              _errorText!,
                              style: TextStyle(
                                color: theme.colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                onPressed: _isSaving
                                    ? null
                                    : () => Navigator.of(
                                        context,
                                      ).pop(NutritionReviewAction.retry),
                                child: const LocalizedText('Try again'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _isSaving || widget.items.isEmpty
                                    ? null
                                    : _save,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),
                                ),
                                icon: _isSaving
                                    ? const SizedBox.square(
                                        dimension: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 20,
                                      ),
                                label: LocalizedText(
                                  _isSaving ? 'Saving...' : 'Confirm log',
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
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    double total(double Function(NutritionReviewItem) value) =>
        widget.items.fold(0, (sum, item) => sum + value(item));
    final metrics = [
      (
        'Calories',
        '${total((item) => item.calories).round()} kcal',
        Theme.of(context).colorScheme.primary,
      ),
      (
        'Protein',
        '${total((item) => item.proteinG).round()} g',
        const Color(0xFFE85882),
      ),
      (
        'Carbs',
        '${total((item) => item.carbsG).round()} g',
        const Color(0xFF4F72E8),
      ),
      (
        'Fat',
        '${total((item) => item.fatG).round()} g',
        const Color(0xFFE6A02D),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.maxWidth < 480 ||
                MediaQuery.textScalerOf(context).scale(14) > 20
            ? 2
            : 4;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final (label, value, color) in metrics)
              Container(
                width: width,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocalizedText(
                      value,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LocalizedText(
                      label,
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReviewFoodCard extends StatelessWidget {
  final NutritionReviewItem item;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ReviewFoodCard({
    super.key,
    required this.item,
    required this.enabled,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: pageBorderColor(context)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: pageSubtleSurfaceColor(context),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          enabled: enabled,
          maintainState: true,
          shape: shape,
          collapsedShape: shape,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _foodEmoji(item.foodName),
                    style: const TextStyle(fontSize: 27),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.foodName,
                      style: TextStyle(
                        color: pagePrimaryTextColor(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatAmount(item.servingQty)} ${item.servingUnit} · ${item.calories.round()} kcal',
                      style: TextStyle(
                        color: pageSecondaryTextColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          children: [
            const SizedBox(height: 8),
            _textField(
              context,
              'Food',
              item.foodName,
              (value) => item.foodName = value,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    context,
                    'Qty',
                    item.servingQty,
                    (value) => item.servingQty = value,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    context,
                    'Unit',
                    item.servingUnit,
                    (value) => item.servingUnit = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    context,
                    'Calories',
                    item.calories,
                    (value) => item.calories = value,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numberField(
                    context,
                    'Protein (g)',
                    item.proteinG,
                    (value) => item.proteinG = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _numberField(
                    context,
                    'Carbs (g)',
                    item.carbsG,
                    (value) => item.carbsG = value,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _numberField(
                    context,
                    'Fat (g)',
                    item.fatG,
                    (value) => item.fatG = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: enabled ? onRemove : null,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const LocalizedText('Remove food'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _decoration(BuildContext context, String label) =>
      InputDecoration(
        labelText: label.localizedCopy(context),
        filled: true,
        fillColor: pageSurfaceColor(context),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: pageBorderColor(context)),
        ),
      );

  Widget _textField(
    BuildContext context,
    String label,
    String value,
    ValueChanged<String> update,
  ) => TextFormField(
    initialValue: value,
    enabled: enabled,
    textInputAction: TextInputAction.next,
    decoration: _decoration(context, label),
    onChanged: (value) {
      update(value);
      onChanged();
    },
  );

  Widget _numberField(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> update,
  ) => TextFormField(
    initialValue: _formatAmount(value),
    enabled: enabled,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    textInputAction: TextInputAction.next,
    decoration: _decoration(context, label),
    onChanged: (value) {
      final parsed = double.tryParse(value);
      update(parsed != null && parsed.isFinite ? parsed : 0);
      onChanged();
    },
  );
}

String _formatAmount(double value) =>
    value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

// Match whole food words, prioritizing dishes before their ingredients.
String _foodEmoji(String name) {
  final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  const foods = <String, String>{
    'pizza': '🍕',
    'burger|hamburger': '🍔',
    'sandwich': '🥪',
    'taco': '🌮',
    'burrito|wrap': '🌯',
    'sushi': '🍣',
    'noodle|noodles|ramen|pancit': '🍜',
    'pasta|spaghetti|lasagna': '🍝',
    'salad': '🥗',
    'soup|stew|sinigang|tinola|bulalo': '🍲',
    'curry': '🍛',
    'dumpling|dumplings|siomai|gyoza': '🥟',
    'pancake|pancakes': '🥞',
    'waffle|waffles': '🧇',
    'fries': '🍟',
    'hotdog|sausage': '🌭',
    'bacon': '🥓',
    'chicken|turkey|manok': '🍗',
    'beef|steak|pork|lechon|adobo': '🥩',
    'fish|salmon|tuna|tilapia|bangus': '🐟',
    'shrimp|prawn|prawns': '🍤',
    'egg|eggs|omelet|omelette': '🥚',
    'rice|sinangag': '🍚',
    'bread|toast|pandesal': '🍞',
    'croissant': '🥐',
    'potato|potatoes': '🥔',
    'corn': '🌽',
    'carrot|carrots': '🥕',
    'broccoli': '🥦',
    'cucumber': '🥒',
    'tomato|tomatoes': '🍅',
    'avocado': '🥑',
    'mushroom|mushrooms': '🍄',
    'vegetable|vegetables|spinach|lettuce|greens|kangkong': '🥬',
    'banana|bananas': '🍌',
    'apple|apples': '🍎',
    'orange|oranges': '🍊',
    'mango': '🥭',
    'pineapple': '🍍',
    'watermelon': '🍉',
    'grape|grapes': '🍇',
    'strawberry|strawberries': '🍓',
    'blueberry|blueberries': '🫐',
    'peach': '🍑',
    'pear': '🍐',
    'cheese': '🧀',
    'milk|yogurt|yoghurt': '🥛',
    'coffee': '☕',
    'tea': '🍵',
    'juice|smoothie': '🧃',
    'cake': '🍰',
    'cookie|cookies|biscuit': '🍪',
    'chocolate': '🍫',
    'donut|doughnut': '🍩',
    'ice cream': '🍨',
    'oat|oats|oatmeal|cereal|porridge': '🥣',
    'peanut|peanuts|almond|almonds|nuts': '🥜',
    'bean|beans|lentils': '🫘',
  };
  for (final entry in foods.entries) {
    if (RegExp('\\b(?:${entry.key})\\b').hasMatch(normalized)) {
      return entry.value;
    }
  }
  return '🍽️';
}
