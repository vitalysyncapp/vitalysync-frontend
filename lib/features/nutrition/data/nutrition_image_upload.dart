import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class NutritionImageUpload {
  NutritionImageUpload._();

  static http.MultipartFile multipart(Uint8List jpegBytes) {
    return http.MultipartFile.fromBytes(
      'image',
      jpegBytes,
      filename: 'meal.jpg',
      contentType: MediaType('image', 'jpeg'),
    );
  }
}
