import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:universal_html/html.dart' as html;
import 'package:vitalysync/shared/config/api_config.dart';

class ReportService {
  Future<void> exportAndOpenUserReport(int userId) async {
    try {
      final url = Uri.parse(ApiConfig.reports('/export/$userId'));
      final headers = await ApiConfig.authHeaders();
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        if (kIsWeb) {
          final base64 = base64Encode(bytes);
          final anchor = html.AnchorElement(
              href: 'data:application/octet-stream;base64,$base64')
            ..target = 'blank'
            ..download = 'Wellness_Report.docx';
          html.document.body?.append(anchor);
          anchor.click();
          anchor.remove();
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final file = File('${directory.path}/Wellness_Report.docx');
          
          await file.writeAsBytes(bytes);
          
          final result = await OpenFilex.open(file.path);
          if (result.type != ResultType.done) {
            throw Exception("Could not open file: ${result.message}");
          }
        }
      } else {
        throw Exception("Failed to generate report: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint('Error exporting report: $e');
      rethrow;
    }
  }
}
