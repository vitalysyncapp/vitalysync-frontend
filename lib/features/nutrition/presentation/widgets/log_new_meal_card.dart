import 'dart:io';

import 'package:flutter/material.dart';

import 'white_card.dart';

class LogNewMealCard extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseFromGallery;
  final VoidCallback onAnalyze;
  final ValueChanged<String> onMealTypeChanged;
  final bool Function(String mealType)? canSelectMealType;
  final ValueChanged<String>? onLockedMealTypeTap;
  final File? selectedImage;
  final String selectedMealType;
  final bool isAnalyzing;

  const LogNewMealCard({
    super.key,
    required this.onTakePhoto,
    required this.onChooseFromGallery,
    required this.onAnalyze,
    required this.onMealTypeChanged,
    required this.selectedMealType,
    required this.isAnalyzing,
    this.canSelectMealType,
    this.onLockedMealTypeTap,
    this.selectedImage,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return WhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Log New Meal',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          SizedBox(height: isCompact ? 14 : 18),
          MealTypeChoices(
            selectedMealType: selectedMealType,
            onMealTypeChanged: onMealTypeChanged,
            canSelectMealType: canSelectMealType,
            onLockedMealTypeTap: onLockedMealTypeTap,
          ),
          SizedBox(height: isCompact ? 14 : 18),
          InkWell(
            borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
            onTap: onTakePhoto,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 24 : 36,
                horizontal: isCompact ? 16 : 20,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F7FF),
                borderRadius: BorderRadius.circular(isCompact ? 18 : 22),
                border: Border.all(color: const Color(0xFF82B5FF), width: 1.4),
              ),
              child: Column(
                children: [
                  if (selectedImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                      child: Image.file(
                        selectedImage!,
                        height: isCompact ? 140 : 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: isCompact ? 12 : 16),
                  ] else ...[
                    Container(
                      width: isCompact ? 64 : 82,
                      height: isCompact ? 64 : 82,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: isCompact ? 28 : 34,
                      ),
                    ),
                    SizedBox(height: isCompact ? 12 : 16),
                  ],
                  Text(
                    'Take Photo',
                    style: TextStyle(
                      fontSize: isCompact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  SizedBox(height: isCompact ? 4 : 6),
                  Text(
                    selectedImage == null
                        ? 'Snap a picture of your meal'
                        : 'Tap to retake meal photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 13 : 14,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isCompact ? 14 : 18),
          InkWell(
            borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
            onTap: onChooseFromGallery,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 14 : 18,
                horizontal: isCompact ? 14 : 16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: const Color(0xFF475569),
                    size: isCompact ? 22 : 26,
                  ),
                  SizedBox(width: isCompact ? 8 : 10),
                  Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontSize: isCompact ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isCompact ? 14 : 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAnalyzing ? null : onAnalyze,
              icon: isAnalyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(isAnalyzing ? 'Analyzing...' : 'Analyze Meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MealTypeChoices extends StatelessWidget {
  final String selectedMealType;
  final ValueChanged<String> onMealTypeChanged;
  final bool Function(String mealType)? canSelectMealType;
  final ValueChanged<String>? onLockedMealTypeTap;

  const MealTypeChoices({
    super.key,
    required this.selectedMealType,
    required this.onMealTypeChanged,
    this.canSelectMealType,
    this.onLockedMealTypeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: nutritionMealTypeChoices.map((choice) {
        final isSelected = selectedMealType == choice.value;
        return ChoiceChip(
          label: Text(choice.label),
          selected: isSelected,
          onSelected: (_) {
            final canSelect = canSelectMealType?.call(choice.value) ?? true;
            if (canSelect) {
              onMealTypeChanged(choice.value);
              return;
            }

            onLockedMealTypeTap?.call(choice.value);
          },
          selectedColor: const Color(0xFFDCFCE7),
          labelStyle: TextStyle(
            color: isSelected
                ? const Color(0xFF15803D)
                : const Color(0xFF475569),
            fontWeight: FontWeight.w700,
          ),
        );
      }).toList(),
    );
  }
}

const nutritionMealTypeChoices = [
  MealChoice(label: 'Breakfast', value: 'breakfast'),
  MealChoice(label: 'Lunch', value: 'lunch'),
  MealChoice(label: 'Dinner', value: 'dinner'),
  MealChoice(label: 'Snack', value: 'snack'),
];

class MealChoice {
  final String label;
  final String value;

  const MealChoice({required this.label, required this.value});
}
