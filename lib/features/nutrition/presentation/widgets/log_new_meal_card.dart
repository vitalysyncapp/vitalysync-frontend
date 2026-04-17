import 'dart:io';

import 'package:flutter/material.dart';

import 'white_card.dart';

class LogNewMealCard extends StatelessWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onChooseFromGallery;
  final File? selectedImage;

  const LogNewMealCard({
    Key? key,
    required this.onTakePhoto,
    required this.onChooseFromGallery,
    this.selectedImage,
  }) : super(key: key);

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
                border: Border.all(
                  color: const Color(0xFF82B5FF),
                  width: 1.4,
                ),
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
        ],
      ),
    );
  }
}
