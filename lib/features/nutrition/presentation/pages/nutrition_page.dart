import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/main_navigation.dart';
import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../../../../shared/widgets/reveal_on_build.dart';
import '../../data/nutrition_api.dart';
import '../../data/nutrition_reminder_engine.dart';
import '../widgets/log_new_meal_card.dart';
import '../widgets/macro_balance_card.dart';
import '../widgets/nutrition_header_card.dart';
import '../widgets/today_nutrition_card.dart';
import '../widgets/todays_meals_card.dart';
import '../widgets/white_card.dart';

part 'manual_log_dialog.dart';

const List<String> _standardNutritionMealTypes = [
  'breakfast',
  'lunch',
  'dinner',
];

String _timeBasedMealType([DateTime? now]) {
  final localNow = now ?? DateTime.now();
  final hour = localNow.hour;

  if (hour >= 4 && hour < 11) {
    return 'breakfast';
  }
  if (hour >= 11 && hour < 17) {
    return 'lunch';
  }
  return 'dinner';
}

String _recommendedMealType(DailyNutritionSummary summary) {
  final preferredMealType = _timeBasedMealType();
  final preferredIndex = _standardNutritionMealTypes.indexOf(preferredMealType);
  final searchStart = preferredIndex < 0 ? 0 : preferredIndex;

  for (final mealType in _standardNutritionMealTypes.skip(searchStart)) {
    if (summary.logged[mealType] != true) {
      return mealType;
    }
  }

  return 'dinner';
}

bool _isLoggedStandardMeal(Map<String, bool> loggedMealTypes, String mealType) {
  return mealType != 'snack' &&
      _standardNutritionMealTypes.contains(mealType) &&
      loggedMealTypes[mealType] == true;
}

String _mealTypeLabel(String mealType) {
  switch (mealType) {
    case 'breakfast':
      return 'Breakfast';
    case 'lunch':
      return 'Lunch';
    case 'dinner':
      return 'Dinner';
    case 'snack':
      return 'Snack';
    default:
      return 'Meal';
  }
}

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
  late String _selectedMealType;
  bool _isAnalyzing = false;
  bool _isSaving = false;
  bool _isLoadingDaily = true;
  int? _attemptId;
  int _handledNutritionLogFocusRequest = 0;
  int _lockedMealTapCount = 0;
  String? _lockedMealTapType;
  DateTime? _lockedMealLastTapAt;
  final Set<String> _unlockedLoggedMealTypes = {};
  List<NutritionReviewItem> _reviewItems = [];
  DailyNutritionSummary _dailySummary = DailyNutritionSummary.empty();

  @override
  void initState() {
    super.initState();
    _selectedMealType = _recommendedMealType(_dailySummary);
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
    final result = await showDialog<_ManualLogResult>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _ManualLogDialog(
        initialMealType: _selectedMealType,
        loggedMealTypes: _dailySummary.logged,
      ),
    );

    if (!mounted || result == null || result.meals.isEmpty) {
      return;
    }

    setState(() {
      if (result.allowLoggedMealUpdate) {
        _unlockedLoggedMealTypes.add(result.mealType);
      }
      _selectedMealType = result.mealType;
      _attemptId = null;
      _reviewItems = [];
    });

    await _analyzeManualMeals(result.meals);
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

  Future<void> _loadDailyNutrition({
    bool showErrors = true,
    bool resetMealUnlocks = false,
  }) async {
    try {
      final summary = await NutritionApi.fetchDaily();
      if (!mounted) return;
      setState(() {
        if (resetMealUnlocks) {
          _unlockedLoggedMealTypes.clear();
          _lockedMealTapCount = 0;
          _lockedMealTapType = null;
          _lockedMealLastTapAt = null;
        }
        _dailySummary = summary;
        _syncSelectedMealTypeWithSummary(summary);
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

    if (_isSelectedMealTypeLocked()) {
      _showLockedMealTypeMessage(_selectedMealType);
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
    if (_isSelectedMealTypeLocked()) {
      _showLockedMealTypeMessage(_selectedMealType);
      return;
    }

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
      await _loadDailyNutrition(showErrors: false, resetMealUnlocks: true);
      unawaited(
        NutritionReminderEngine.instance.evaluate(allowNotification: false),
      );
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

  void _syncSelectedMealTypeWithSummary(DailyNutritionSummary summary) {
    if (_selectedMealType == 'snack') {
      return;
    }

    if (!_isLoggedStandardMeal(summary.logged, _selectedMealType) ||
        _unlockedLoggedMealTypes.contains(_selectedMealType)) {
      return;
    }

    _selectedMealType = _recommendedMealType(summary);
  }

  bool _canSelectMealType(String mealType) {
    return !_isLoggedStandardMeal(_dailySummary.logged, mealType) ||
        _unlockedLoggedMealTypes.contains(mealType);
  }

  bool _isSelectedMealTypeLocked() {
    return !_canSelectMealType(_selectedMealType);
  }

  void _selectMealType(String mealType) {
    setState(() {
      _selectedMealType = mealType;
      _attemptId = null;
      _reviewItems = [];
    });
  }

  void _handleLockedMealTypeTap(String mealType) {
    final now = DateTime.now();
    final isSameMeal = _lockedMealTapType == mealType;
    final isQuickTap =
        _lockedMealLastTapAt != null &&
        now.difference(_lockedMealLastTapAt!) <=
            const Duration(milliseconds: 900);

    _lockedMealTapType = mealType;
    _lockedMealLastTapAt = now;
    _lockedMealTapCount = isSameMeal && isQuickTap
        ? _lockedMealTapCount + 1
        : 1;

    if (_lockedMealTapCount >= 3) {
      setState(() {
        _unlockedLoggedMealTypes.add(mealType);
        _selectedMealType = mealType;
        _attemptId = null;
        _reviewItems = [];
      });
      _lockedMealTapCount = 0;
      _lockedMealTapType = null;
      _lockedMealLastTapAt = null;
      _showSnackBar('${_mealTypeLabel(mealType)} unlocked for editing.');
      return;
    }

    if (_lockedMealTapCount == 1) {
      _showLockedMealTypeMessage(mealType);
    }
  }

  void _showLockedMealTypeMessage(String mealType) {
    _showSnackBar(
      '${_mealTypeLabel(mealType)} is already logged. Triple-tap it to edit.',
    );
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
          ..._reviewItems.asMap().entries.map((entry) {
            final editor = _ReviewItemEditor(
              key: ValueKey('review-${entry.key}-${entry.value.foodName}'),
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

            return KeyedSubtree(key: _firstReviewItemKey, child: editor);
          }),
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
                      onMealTypeChanged: _selectMealType,
                      canSelectMealType: _canSelectMealType,
                      onLockedMealTypeTap: _handleLockedMealTypeTap,
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
