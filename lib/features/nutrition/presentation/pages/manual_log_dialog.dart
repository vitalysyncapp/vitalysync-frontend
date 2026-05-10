part of 'nutrition_page.dart';

class _ManualLogDialog extends StatefulWidget {
  final String initialMealType;
  final Map<String, bool> loggedMealTypes;

  const _ManualLogDialog({
    required this.initialMealType,
    required this.loggedMealTypes,
  });

  @override
  State<_ManualLogDialog> createState() => _ManualLogDialogState();
}

class _ManualLogDialogState extends State<_ManualLogDialog> {
  final List<_ManualMealDraft> _drafts = [_ManualMealDraft()];
  late String _selectedMealType;
  final Set<String> _unlockedLoggedMealTypes = {};
  int _lockedMealTapCount = 0;
  String? _lockedMealTapType;
  DateTime? _lockedMealLastTapAt;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType;
  }

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
    if (!_canSelectMealType(_selectedMealType)) {
      setState(() {
        _errorText =
            'Triple-tap ${_mealTypeLabel(_selectedMealType)} to update the existing log.';
      });
      return;
    }

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
      _ManualLogResult(
        mealType: _selectedMealType,
        allowLoggedMealUpdate: _unlockedLoggedMealTypes.contains(
          _selectedMealType,
        ),
        meals: filledDrafts
            .map(
              (draft) => ManualNutritionInput(
                mealName: draft.mealName,
                quantity: draft.quantity,
                notes: draft.notes,
              ),
            )
            .toList(),
      ),
    );
  }

  bool _canSelectMealType(String mealType) {
    return !_isLoggedStandardMeal(widget.loggedMealTypes, mealType) ||
        _unlockedLoggedMealTypes.contains(mealType);
  }

  void _selectMealType(String mealType) {
    setState(() {
      _selectedMealType = mealType;
      _errorText = null;
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

    setState(() {
      if (_lockedMealTapCount >= 3) {
        _unlockedLoggedMealTypes.add(mealType);
        _selectedMealType = mealType;
        _lockedMealTapCount = 0;
        _lockedMealTapType = null;
        _lockedMealLastTapAt = null;
        _errorText = null;
        return;
      }

      if (_lockedMealTapCount == 1) {
        _errorText =
            '${_mealTypeLabel(mealType)} is already logged. Triple-tap it to edit.';
      }
    });
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MealTypeChoices(
                          selectedMealType: _selectedMealType,
                          onMealTypeChanged: _selectMealType,
                          canSelectMealType: _canSelectMealType,
                          onLockedMealTypeTap: _handleLockedMealTypeTap,
                        ),
                        SizedBox(height: isCompact ? 12 : 14),
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

class _ManualLogResult {
  final String mealType;
  final bool allowLoggedMealUpdate;
  final List<ManualNutritionInput> meals;

  const _ManualLogResult({
    required this.mealType,
    required this.allowLoggedMealUpdate,
    required this.meals,
  });
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
