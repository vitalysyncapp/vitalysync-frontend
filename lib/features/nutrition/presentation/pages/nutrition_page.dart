import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../../data/nutrition_api.dart';
import '../widgets/log_new_meal_card.dart';
import '../widgets/macro_balance_card.dart';
import '../widgets/nutrition_header_card.dart';
import '../widgets/today_nutrition_card.dart';
import '../widgets/todays_meals_card.dart';
import '../widgets/white_card.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({Key? key}) : super(key: key);

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String _selectedMealType = 'breakfast';
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _isLoadingDaily = true;
  int? _attemptId;
  List<NutritionReviewItem> _reviewItems = [];
  DailyNutritionSummary _dailySummary = DailyNutritionSummary.empty();

  @override
  void initState() {
    super.initState();
    _loadDailyNutrition(showErrors: false);
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
      });

      _showSnackBar('Photo captured successfully');
    } catch (e) {
      _showSnackBar('Failed to open camera');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
      });

      _showSnackBar('Image selected from gallery');
    } catch (e) {
      _showSnackBar('Failed to open gallery');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onAddMeal() {
    _showSnackBar('Choose a meal type and add a food photo.');
  }

  Future<void> _loadDailyNutrition({bool showErrors = true}) async {
    try {
      final summary = await NutritionApi.fetchDaily();
      if (!mounted) return;
      setState(() {
        _dailySummary = summary;
        _isLoadingDaily = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingDaily = false;
      });
      if (showErrors) {
        _showSnackBar(_friendlyError(e));
      }
    }
  }

  Future<void> _analyzeSelectedMeal() async {
    if (_selectedImage == null) {
      _showSnackBar('Please choose or take a food photo first.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _reviewItems = [];
      _attemptId = null;
    });

    try {
      final result = await NutritionApi.analyzeMeal(
        image: _selectedImage!,
        mealType: _selectedMealType,
        logDate: NutritionApi.todayKey(),
      );

      if (!mounted) return;
      setState(() {
        _attemptId = result.attemptId;
        _reviewItems = result.items;
      });
      _showSnackBar('Review the detected food before saving.');
    } catch (e) {
      _showSnackBar(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    }
  }

  Future<void> _confirmMeal() async {
    final attemptId = _attemptId;
    if (attemptId == null || _reviewItems.isEmpty) {
      _showSnackBar('Analyze a meal before confirming.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await NutritionApi.confirmMeal(
        attemptId: attemptId,
        mealType: _selectedMealType,
        logDate: NutritionApi.todayKey(),
        items: _reviewItems,
      );

      if (!mounted) return;
      setState(() {
        _selectedImage = null;
        _attemptId = null;
        _reviewItems = [];
      });
      await _loadDailyNutrition(showErrors: false);
      _showSnackBar('Meal saved successfully.');
    } catch (e) {
      _showSnackBar(_friendlyError(e));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _cancelReview() async {
    final attemptId = _attemptId;
    if (attemptId != null) {
      try {
        await NutritionApi.discardAttempt(attemptId);
      } catch (_) {
        // The attempt is only a draft; local cleanup still keeps the UI usable.
      }
    }

    if (!mounted) return;
    setState(() {
      _attemptId = null;
      _reviewItems = [];
    });
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    return message;
  }

  Widget _buildReviewCard() {
    final isCompact = MediaQuery.of(context).size.width < 380;

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review Meal',
            style: TextStyle(
              fontSize: isCompact ? 17 : 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: isCompact ? 12 : 16),
          ..._reviewItems.asMap().entries.map(
                (entry) => _ReviewItemEditor(
                  key: ValueKey('review-${entry.key}-${entry.value.foodName}'),
                  item: entry.value,
                  isCompact: isCompact,
                  onChanged: () => setState(() {}),
                  onRemove: () {
                    setState(() {
                      _reviewItems.removeAt(entry.key);
                    });
                  },
                ),
              ),
          SizedBox(height: isCompact ? 10 : 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _cancelReview,
                  child: const Text('Cancel'),
                ),
              ),
              SizedBox(width: isCompact ? 8 : 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _analyzeSelectedMeal,
                  child: const Text('Try Again'),
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _confirmMeal,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline_rounded),
              label: Text(_isSaving ? 'Saving...' : 'Confirm Log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;
    final pagePadding = isCompact ? 12.0 : 16.0;
    final sectionSpacing = isCompact ? 12.0 : 16.0;

    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildAppBar(context),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              pagePadding,
              pagePadding,
              pagePadding,
              pageBottomContentPadding(context, extra: 20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RevealOnBuild(child: NutritionHeaderCard()),
                SizedBox(height: sectionSpacing),
                RevealOnBuild(
                  delay: const Duration(milliseconds: 70),
                  child: TodayNutritionCard(
                    calories: _dailySummary.totalCalories,
                    proteinG: _dailySummary.totalProteinG,
                    carbsG: _dailySummary.totalCarbsG,
                    fatG: _dailySummary.totalFatG,
                  ),
                ),
                SizedBox(height: sectionSpacing),
                RevealOnBuild(
                  delay: const Duration(milliseconds: 140),
                  child: LogNewMealCard(
                    selectedImage: _selectedImage,
                    selectedMealType: _selectedMealType,
                    isAnalyzing: _isAnalyzing,
                    onTakePhoto: _pickFromCamera,
                    onChooseFromGallery: _pickFromGallery,
                    onAnalyze: _analyzeSelectedMeal,
                    onMealTypeChanged: (value) {
                      setState(() {
                        _selectedMealType = value;
                        _attemptId = null;
                        _reviewItems = [];
                      });
                    },
                  ),
                ),
                if (_reviewItems.isNotEmpty) ...[
                  SizedBox(height: sectionSpacing),
                  RevealOnBuild(
                    delay: const Duration(milliseconds: 180),
                    child: _buildReviewCard(),
                  ),
                ],
                SizedBox(height: sectionSpacing),
                RevealOnBuild(
                  delay: const Duration(milliseconds: 210),
                  child: _isLoadingDaily
                      ? const Center(child: CircularProgressIndicator())
                      : TodaysMealsCard(
                          onAddTap: _onAddMeal,
                          meals: _dailySummary.meals,
                        ),
                ),
                SizedBox(height: sectionSpacing),
                RevealOnBuild(
                  delay: const Duration(milliseconds: 280),
                  child: MacroBalanceCard(
                    proteinG: _dailySummary.totalProteinG,
                    carbsG: _dailySummary.totalCarbsG,
                    fatG: _dailySummary.totalFatG,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewItemEditor extends StatelessWidget {
  final NutritionReviewItem item;
  final bool isCompact;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _ReviewItemEditor({
    Key? key,
    required this.item,
    required this.isCompact,
    required this.onChanged,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 10 : 14),
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _textField(
                  label: 'Food',
                  initialValue: item.foodName,
                  onChanged: (value) {
                    item.foodName = value;
                    onChanged();
                  },
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 10),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: 'Qty',
                  initialValue: item.servingQty,
                  onChanged: (value) {
                    item.servingQty = value;
                    onChanged();
                  },
                ),
              ),
              SizedBox(width: isCompact ? 8 : 10),
              Expanded(
                child: _textField(
                  label: 'Unit',
                  initialValue: item.servingUnit,
                  onChanged: (value) {
                    item.servingUnit = value;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 10),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: 'Cal',
                  initialValue: item.calories,
                  onChanged: (value) {
                    item.calories = value;
                    onChanged();
                  },
                ),
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Expanded(
                child: _numberField(
                  label: 'Protein',
                  initialValue: item.proteinG,
                  onChanged: (value) {
                    item.proteinG = value;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 10),
          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: 'Carbs',
                  initialValue: item.carbsG,
                  onChanged: (value) {
                    item.carbsG = value;
                    onChanged();
                  },
                ),
              ),
              SizedBox(width: isCompact ? 6 : 8),
              Expanded(
                child: _numberField(
                  label: 'Fat',
                  initialValue: item.fatG,
                  onChanged: (value) {
                    item.fatG = value;
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required String label,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged,
    );
  }

  Widget _numberField({
    required String label,
    required double initialValue,
    required ValueChanged<double> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue.toStringAsFixed(
        initialValue == initialValue.roundToDouble() ? 0 : 1,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label),
      onChanged: (value) => onChanged(double.tryParse(value) ?? 0),
    );
  }
}
