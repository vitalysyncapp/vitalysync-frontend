import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/main_navigation.dart';
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
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _logNewMealCardKey = GlobalKey();
  final GlobalKey _firstReviewItemKey = GlobalKey();
  File? _selectedImage;
  String _selectedMealType = 'breakfast';
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _isLoadingDaily = true;
  int? _attemptId;
  int _handledNutritionLogFocusRequest = 0;
  List<NutritionReviewItem> _reviewItems = [];
  DailyNutritionSummary _dailySummary = DailyNutritionSummary.empty();

  @override
  void initState() {
    super.initState();
    _loadDailyNutrition(showErrors: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = MainNavigationController.maybeOf(context);
    if (controller == null || controller.currentIndex != 2) {
      return;
    }

    final request = controller.nutritionLogFocusRequest;
    if (request <= _handledNutritionLogFocusRequest) {
      return;
    }

    _handledNutritionLogFocusRequest = request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLogNewMealCard();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _onAddMeal() async {
    final meals = await showDialog<List<ManualNutritionInput>>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => const _ManualLogDialog(),
    );

    if (!mounted || meals == null || meals.isEmpty) {
      return;
    }

    await _analyzeManualMeals(meals);
  }

  Future<void> _scrollToLogNewMealCard() async {
    final targetContext = _logNewMealCardKey.currentContext;
    if (!mounted || targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
      alignment: 0.06,
    );
  }

  Future<void> _scrollToFirstReviewItem() async {
    final targetContext = _firstReviewItemKey.currentContext;
    if (!mounted || targetContext == null) {
      return;
    }

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeInOutCubic,
      alignment: 0.12,
    );
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
      if (result.items.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToFirstReviewItem();
        });
      }
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

  Future<void> _analyzeManualMeals(List<ManualNutritionInput> meals) async {
    setState(() {
      _isAnalyzing = true;
      _reviewItems = [];
      _attemptId = null;
    });

    try {
      final result = await NutritionApi.analyzeManualMeal(
        meals: meals,
        mealType: _selectedMealType,
        logDate: NutritionApi.todayKey(),
      );

      if (!mounted) return;
      setState(() {
        _selectedImage = null;
        _attemptId = result.attemptId;
        _reviewItems = result.items;
      });
      if (result.items.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToFirstReviewItem();
        });
      }
      _showSnackBar('Review the estimated food before saving.');
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
                (entry) {
                  final editor = _ReviewItemEditor(
                    key: ValueKey(
                      'review-${entry.key}-${entry.value.foodName}',
                    ),
                    item: entry.value,
                    isCompact: isCompact,
                    onChanged: () => setState(() {}),
                    onRemove: () {
                      setState(() {
                        _reviewItems.removeAt(entry.key);
                      });
                    },
                  );

                  if (entry.key != 0) {
                    return editor;
                  }

                  return KeyedSubtree(
                    key: _firstReviewItemKey,
                    child: editor,
                  );
                },
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
            controller: _scrollController,
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
                  child: Container(
                    key: _logNewMealCardKey,
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

class _ManualLogDialog extends StatefulWidget {
  const _ManualLogDialog();

  @override
  State<_ManualLogDialog> createState() => _ManualLogDialogState();
}

class _ManualLogDialogState extends State<_ManualLogDialog> {
  final List<_ManualMealDraft> _drafts = [_ManualMealDraft()];
  String? _errorText;

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addMealForm() {
    setState(() {
      _errorText = null;
      _drafts.add(_ManualMealDraft());
    });
  }

  void _removeMealForm(int index) {
    if (_drafts.length == 1) {
      _drafts[index].clear();
      return;
    }

    setState(() {
      _errorText = null;
      final removed = _drafts.removeAt(index);
      removed.dispose();
    });
  }

  void _submit() {
    final filledDrafts = _drafts.where((draft) => draft.hasAnyInput).toList();

    if (filledDrafts.isEmpty) {
      setState(() {
        _errorText = 'Add at least one meal to analyze.';
      });
      return;
    }

    final hasIncompleteDraft = filledDrafts.any(
      (draft) => draft.mealName.isEmpty || draft.quantity.isEmpty,
    );

    if (hasIncompleteDraft) {
      setState(() {
        _errorText = 'Meal name and quantity are required.';
      });
      return;
    }

    Navigator.of(context).pop(
      filledDrafts
          .map(
            (draft) => ManualNutritionInput(
              mealName: draft.mealName,
              quantity: draft.quantity,
              notes: draft.notes,
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 380;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14 : 22,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
          child: Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? 16 : 20,
                    isCompact ? 16 : 20,
                    isCompact ? 8 : 12,
                    10,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Manual Log',
                              style: TextStyle(
                                fontSize: isCompact ? 18 : 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Estimate nutrition from typed meal details.',
                              style: TextStyle(
                                fontSize: isCompact ? 12 : 13,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Use English food names for better estimates.',
                              style: TextStyle(
                                fontSize: isCompact ? 11.5 : 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _addMealForm,
                        tooltip: 'Add meal',
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: const Color(0xFF16A34A),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 16 : 20,
                    ),
                    child: Column(
                      children: [
                        ..._drafts.asMap().entries.map(
                              (entry) => _ManualMealForm(
                                key: ValueKey(entry.value.id),
                                draft: entry.value,
                                index: entry.key,
                                canRemove: _drafts.length > 1,
                                onRemove: () => _removeMealForm(entry.key),
                                isCompact: isCompact,
                              ),
                            ),
                        if (_errorText != null) ...[
                          const SizedBox(height: 2),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _errorText!,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isCompact ? 16 : 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: isCompact ? 10 : 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Analyze'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: isCompact ? 12 : 14,
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
        ),
      ),
    );
  }
}

class _ManualMealDraft {
  static int _nextId = 0;

  final int id = _nextId++;
  final TextEditingController mealNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String get mealName => mealNameController.text.trim();
  String get quantity => quantityController.text.trim();
  String get notes => notesController.text.trim();

  bool get hasAnyInput =>
      mealName.isNotEmpty || quantity.isNotEmpty || notes.isNotEmpty;

  void clear() {
    mealNameController.clear();
    quantityController.clear();
    notesController.clear();
  }

  void dispose() {
    mealNameController.dispose();
    quantityController.dispose();
    notesController.dispose();
  }
}

class _ManualMealForm extends StatelessWidget {
  final _ManualMealDraft draft;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final bool isCompact;

  const _ManualMealForm({
    super.key,
    required this.draft,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 12 : 14),
      padding: EdgeInsets.all(isCompact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Meal ${index + 1}',
                  style: TextStyle(
                    fontSize: isCompact ? 14 : 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                onPressed: onRemove,
                tooltip: canRemove ? 'Remove meal' : 'Clear meal',
                icon: Icon(
                  canRemove
                      ? Icons.remove_circle_outline_rounded
                      : Icons.cleaning_services_outlined,
                ),
                color: const Color(0xFFEF4444),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 8 : 10),
          TextField(
            controller: draft.mealNameController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('Meal Name'),
          ),
          SizedBox(height: isCompact ? 8 : 10),
          TextField(
            controller: draft.quantityController,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration('Quantity'),
          ),
          SizedBox(height: isCompact ? 8 : 10),
          TextField(
            controller: draft.notesController,
            minLines: 2,
            maxLines: 4,
            decoration: _inputDecoration('Optional Notes'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
        borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.4),
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
    super.key,
    required this.item,
    required this.isCompact,
    required this.onChanged,
    required this.onRemove,
  });

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
