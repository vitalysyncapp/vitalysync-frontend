import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image_lib;
import 'package:vitalysync/features/nutrition/data/nutrition_image_processor.dart';
import 'package:vitalysync/features/nutrition/data/nutrition_image_upload.dart';

void main() {
  test('meal photos are resized, stripped, and encoded as bounded JPEGs', () {
    final source = image_lib.Image(width: 2600, height: 1200);
    image_lib.fill(source, color: image_lib.ColorRgb8(40, 160, 90));
    source.textData = {'private-note': 'remove me'};
    final sourceBytes = Uint8List.fromList(image_lib.encodePng(source));

    final prepared = NutritionImageProcessor.prepare(sourceBytes);
    final decoded = image_lib.decodeJpg(prepared);

    expect(prepared.take(3), orderedEquals(const [0xFF, 0xD8, 0xFF]));
    expect(prepared.length, lessThanOrEqualTo(7 * 1024 * 1024));
    expect(decoded, isNotNull);
    expect(decoded!.width, NutritionImageProcessor.maxDimension);
    expect(decoded.height, lessThan(NutritionImageProcessor.maxDimension));
    expect(decoded.exif.isEmpty, isTrue);
    expect(decoded.iccProfile, isNull);
    expect(decoded.textData, isNull);
  });

  test('meal photo processing rejects invalid and oversized input', () {
    expect(
      () => NutritionImageProcessor.prepare(
        Uint8List.fromList(List<int>.filled(32, 1)),
      ),
      throwsA(isA<NutritionImageException>()),
    );
    expect(
      () => NutritionImageProcessor.prepare(
        Uint8List(NutritionImageProcessor.maxInputBytes + 1),
      ),
      throwsA(isA<NutritionImageException>()),
    );
  });

  test('meal photo multipart upload declares JPEG content', () {
    final upload = NutritionImageUpload.multipart(
      Uint8List.fromList(const [0xFF, 0xD8, 0xFF, 0xD9]),
    );

    expect(upload.field, 'image');
    expect(upload.filename, 'meal.jpg');
    expect(upload.contentType.mimeType, 'image/jpeg');
  });
}
