import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../../../shared/widgets/app_bar.dart';
import '../widgets/log_new_meal_card.dart';
import '../widgets/macro_balance_card.dart';
import '../widgets/nutrition_header_card.dart';
import '../widgets/today_nutrition_card.dart';
import '../widgets/todays_meals_card.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({Key? key}) : super(key: key);

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onAddMeal() {
    _showSnackBar('Add meal button tapped');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: buildPageDecoration(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: buildAppBar(context),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NutritionHeaderCard(),
                const SizedBox(height: 16),
                const TodayNutritionCard(),
                const SizedBox(height: 16),
                LogNewMealCard(
                  selectedImage: _selectedImage,
                  onTakePhoto: _pickFromCamera,
                  onChooseFromGallery: _pickFromGallery,
                ),
                const SizedBox(height: 16),
                TodaysMealsCard(
                  onAddTap: _onAddMeal,
                ),
                const SizedBox(height: 16),
                const MacroBalanceCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
