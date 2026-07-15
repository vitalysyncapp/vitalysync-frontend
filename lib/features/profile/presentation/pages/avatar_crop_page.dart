import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';

import '../../../../shared/theme/app_page_style.dart';
import '../../data/profile_avatar.dart';

class AvatarCropPage extends StatefulWidget {
  const AvatarCropPage({super.key, required this.imageBytes});

  final Uint8List imageBytes;

  @override
  State<AvatarCropPage> createState() => _AvatarCropPageState();
}

class _AvatarCropPageState extends State<AvatarCropPage> {
  final CropController _cropController = CropController();
  bool _isReady = false;
  bool _isProcessing = false;

  Future<void> _handleCropResult(CropResult result) async {
    try {
      switch (result) {
        case CropSuccess(:final croppedImage):
          final prepared = ProfileAvatarImageProcessor.prepareCroppedPhoto(
            croppedImage,
          );
          if (mounted) Navigator.of(context).pop(prepared);
        case CropFailure(:final cause):
          throw ProfileAvatarException('Unable to crop this photo: $cause');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      final message = error is ProfileAvatarException
          ? error.message
          : 'Unable to process the cropped photo.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _usePhoto() {
    if (!_isReady || _isProcessing) return;
    setState(() => _isProcessing = true);
    _cropController.crop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isProcessing,
      child: Container(
        decoration: buildPageDecoration(context),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: pagePrimaryTextColor(context),
            leading: IconButton(
              onPressed: _isProcessing
                  ? null
                  : () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Cancel crop',
            ),
            title: Text(
              'Adjust photo',
              style: TextStyle(
                color: pagePrimaryTextColor(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
                  child: Text(
                    'Drag to reposition and pinch or scroll to zoom.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: pageSecondaryTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: ColoredBox(
                            color: isDark
                                ? const Color(0xFF0B1624)
                                : const Color(0xFFDFECF2),
                            child: Crop(
                              key: const ValueKey('avatar-crop-editor'),
                              image: widget.imageBytes,
                              controller: _cropController,
                              onCropped: _handleCropResult,
                              onStatusChanged: (status) {
                                final isReady = status == CropStatus.ready;
                                if (mounted && isReady != _isReady) {
                                  setState(() => _isReady = isReady);
                                }
                              },
                              aspectRatio: 1,
                              initialRectBuilder:
                                  InitialRectBuilder.withSizeAndRatio(
                                    size: 0.88,
                                    aspectRatio: 1,
                                  ),
                              withCircleUi: true,
                              interactive: true,
                              fixCropRect: true,
                              baseColor: isDark
                                  ? const Color(0xFF0B1624)
                                  : const Color(0xFFDFECF2),
                              maskColor: Colors.black.withValues(alpha: 0.55),
                              progressIndicator: const Center(
                                child: CircularProgressIndicator(),
                              ),
                              filterQuality: FilterQuality.high,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    pageBottomContentPadding(context),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: const ValueKey('avatar-use-cropped-photo'),
                      onPressed: _isReady && !_isProcessing ? _usePhoto : null,
                      icon: _isProcessing
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _isProcessing ? 'Processing...' : 'Use photo',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D8CA8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
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
