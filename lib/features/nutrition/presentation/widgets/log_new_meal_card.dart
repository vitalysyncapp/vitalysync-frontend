import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cornerRadius = isCompact ? 18.0 : 22.0;

    return WhiteCard(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(cornerRadius),
        topRight: Radius.circular(isCompact ? 50 : 62),
        bottomLeft: Radius.circular(cornerRadius),
        bottomRight: Radius.circular(cornerRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isCompact ? 34 : 38,
                height: isCompact ? 34 : 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D9696), Color(0xFF5DB8F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isCompact ? 11 : 13),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1D9696).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.restaurant_rounded,
                  color: Colors.white,
                  size: isCompact ? 18 : 20,
                ),
              ),
              SizedBox(width: isCompact ? 9 : 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log new meal',
                      style: TextStyle(
                        fontSize: isCompact ? 15.5 : 17,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: pagePrimaryTextColor(context),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose a meal type, then add a photo',
                      style: TextStyle(
                        fontSize: isCompact ? 10.5 : 11.5,
                        color: pageSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: isCompact ? 11 : 14),
          MealTypeChoices(
            selectedMealType: selectedMealType,
            onMealTypeChanged: onMealTypeChanged,
            canSelectMealType: canSelectMealType,
            onLockedMealTypeTap: onLockedMealTypeTap,
          ),
          SizedBox(height: isCompact ? 10 : 12),
          InkWell(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isCompact ? 14 : 17),
              topRight: Radius.circular(isCompact ? 30 : 38),
              bottomLeft: Radius.circular(isCompact ? 14 : 17),
              bottomRight: Radius.circular(isCompact ? 14 : 17),
            ),
            onTap: onTakePhoto,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 11 : 14,
                horizontal: isCompact ? 10 : 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          const Color(0xFF2563EB).withValues(alpha: 0.16),
                          const Color(0xFF1D9696).withValues(alpha: 0.08),
                        ]
                      : const [Color(0xFFF2F7FF), Color(0xFFF2FBF8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isCompact ? 14 : 17),
                  topRight: Radius.circular(isCompact ? 30 : 38),
                  bottomLeft: Radius.circular(isCompact ? 14 : 17),
                  bottomRight: Radius.circular(isCompact ? 14 : 17),
                ),
                border: Border.all(
                  color: const Color(
                    0xFF5B9CF6,
                  ).withValues(alpha: isDark ? 0.42 : 0.78),
                  width: 1.25,
                ),
              ),
              child: Column(
                children: [
                  if (selectedImage != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                      child: Image.file(
                        selectedImage!,
                        height: isCompact ? 82 : 104,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(height: isCompact ? 6 : 7),
                  ] else ...[
                    Container(
                      width: isCompact ? 38 : 46,
                      height: isCompact ? 38 : 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2563EB,
                            ).withValues(alpha: 0.24),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: isCompact ? 19 : 22,
                      ),
                    ),
                    SizedBox(height: isCompact ? 6 : 7),
                  ],
                  Text(
                    'Take photo',
                    style: TextStyle(
                      fontSize: isCompact ? 12.5 : 13.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  SizedBox(height: isCompact ? 2 : 3),
                  Text(
                    selectedImage == null
                        ? 'Snap a picture of your meal'
                        : 'Tap to retake meal photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 10.5 : 11,
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isCompact ? 8 : 10),
          InkWell(
            borderRadius: BorderRadius.circular(isCompact ? 12 : 13),
            onTap: onChooseFromGallery,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                vertical: isCompact ? 8 : 9,
                horizontal: isCompact ? 10 : 12,
              ),
              decoration: BoxDecoration(
                color: pageSubtleSurfaceColor(context),
                borderRadius: BorderRadius.circular(isCompact ? 12 : 13),
                border: Border.all(color: pageBorderColor(context)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    color: isDark
                        ? const Color(0xFF93C5FD)
                        : const Color(0xFF475569),
                    size: isCompact ? 17 : 19,
                  ),
                  SizedBox(width: isCompact ? 6 : 8),
                  Text(
                    'Choose from gallery',
                    style: TextStyle(
                      fontSize: isCompact ? 11.5 : 12.5,
                      fontWeight: FontWeight.w500,
                      color: pagePrimaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: isCompact ? 9 : 11),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isAnalyzing ? null : onAnalyze,
              icon: isAnalyzing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(isAnalyzing ? 'Analyzing...' : 'Analyze meal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF5D4385) : const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: (isDark ? const Color(0xFF5D4385) : const Color(0xFF16A34A)).withValues(alpha: 0.55),
                elevation: 2,
                shadowColor: (isDark ? const Color(0xFF5D4385) : const Color(0xFF16A34A)).withValues(alpha: 0.32),
                padding: EdgeInsets.symmetric(vertical: isCompact ? 10 : 12),
                textStyle: TextStyle(
                  fontSize: isCompact ? 12.5 : 13.5,
                  fontWeight: FontWeight.w700,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isCompact ? 11 : 12),
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
      spacing: 5,
      runSpacing: 5,
      children: nutritionMealTypeChoices.map((choice) {
        final isSelected = selectedMealType == choice.value;
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF8FAFC),
          selectedColor: isDark
              ? const Color(0xFF16A34A).withValues(alpha: 0.2)
              : const Color(0xFFDCFCE7),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF16A34A).withValues(alpha: isDark ? 0.42 : 1)
                : pageBorderColor(context),
          ),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          labelPadding: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          labelStyle: TextStyle(
            color: isSelected
                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D))
                : pageSecondaryTextColor(context),
            fontSize: 11.5,
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
