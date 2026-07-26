import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

class NutritionImageProcessor {
  NutritionImageProcessor._();

  static const maxInputBytes = 20 * 1024 * 1024;
  static const maxOutputBytes = 7 * 1024 * 1024;
  static const maxDimension = 2048;

  static Uint8List prepare(Uint8List sourceBytes) {
    if (sourceBytes.isEmpty || sourceBytes.length > maxInputBytes) {
      throw const NutritionImageException(
        'Choose a food photo smaller than 20 MB.',
      );
    }

    image_lib.Image? decoded;
    try {
      decoded = image_lib.decodeImage(sourceBytes);
    } catch (_) {
      decoded = null;
    }

    if (decoded == null) {
      throw const NutritionImageException(
        'Choose a valid JPEG, PNG, or WebP food photo.',
      );
    }

    var prepared = image_lib.bakeOrientation(decoded);
    if (prepared.width > maxDimension || prepared.height > maxDimension) {
      prepared = prepared.width >= prepared.height
          ? image_lib.copyResize(
              prepared,
              width: maxDimension,
              interpolation: image_lib.Interpolation.average,
            )
          : image_lib.copyResize(
              prepared,
              height: maxDimension,
              interpolation: image_lib.Interpolation.average,
            );
    }

    prepared.exif.clear();
    prepared.iccProfile = null;
    prepared.textData = null;

    for (final quality in const [82, 72, 62, 52]) {
      final encoded = image_lib.encodeJpg(prepared, quality: quality);
      if (encoded.length <= maxOutputBytes) {
        return encoded;
      }
    }

    throw const NutritionImageException(
      'This photo is still too large after processing. Try another image.',
    );
  }
}

class NutritionImageException implements Exception {
  const NutritionImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
