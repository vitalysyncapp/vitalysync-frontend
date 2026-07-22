import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../shared/config/api_config.dart';
import '../../../shared/offline/fetch_policy.dart';
import '../../../shared/offline/offline_cache_store.dart';
import '../../../shared/preferences/user_session.dart';
import 'daily_report_schedule.dart';

const String scheduledInsightReportGenerationCacheNamespace =
    'scheduled_insight_report_generation';

class InsightReport {
  final int insightReportId;
  final int userId;
  final String reportType;
  final String periodStart;
  final String periodEnd;
  final String title;
  final String summary;
  final String priority;
  final Map<String, dynamic> metrics;
  final Map<String, dynamic> sourceSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;

  const InsightReport({
    required this.insightReportId,
    required this.userId,
    required this.reportType,
    required this.periodStart,
    required this.periodEnd,
    required this.title,
    required this.summary,
    required this.priority,
    required this.metrics,
    required this.sourceSnapshot,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InsightReport.fromJson(Map<String, dynamic> json) {
    return InsightReport(
      insightReportId: _parseInt(json['insight_report_id']),
      userId: _parseInt(json['user_id']),
      reportType: json['report_type']?.toString() ?? 'daily',
      periodStart: _dateOnly(json['period_start']),
      periodEnd: _dateOnly(json['period_end']),
      title: json['title']?.toString() ?? 'Wellness report',
      summary: json['summary']?.toString() ?? '',
      priority: json['priority']?.toString() ?? 'low',
      metrics: _mapFromJson(json['metrics']),
      sourceSnapshot: _mapFromJson(json['source_snapshot']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'insight_report_id': insightReportId,
      'user_id': userId,
      'report_type': reportType,
      'period_start': periodStart,
      'period_end': periodEnd,
      'title': title,
      'summary': summary,
      'priority': priority,
      'metrics': metrics,
      'source_snapshot': sourceSnapshot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class InsightReportApi {
  static const Duration _requestTimeout = ApiRequestTimeouts.standard;
  static const Duration _refreshTimeout = ApiRequestTimeouts.coldStart;
  static const String _reportsCache = 'insight_reports';

  static Future<List<InsightReport>> listReports({int limit = 30}) async {
    final userId = await _storedUserId();
    if (userId == null) {
      return const [];
    }

    try {
      final uri = Uri.parse(ApiConfig.adaptive('/insight-reports')).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'limit': limit.toString(),
        },
      );
      final response = await http
          .get(uri, headers: await ApiConfig.jsonHeaders())
          .timeout(_requestTimeout);
      final data = _decodeResponseMap(response);
      if (response.statusCode != 200) {
        return _readCachedReports(userId);
      }

      await OfflineCacheStore.saveJson(
        namespace: _reportsCache,
        scope: userId.toString(),
        data: data,
      );
      return _reportsFromData(data);
    } catch (_) {
      return _readCachedReports(userId);
    }
  }

  static Future<bool> isScheduledRefreshPending({DateTime? now}) async {
    final reportDate = DailyReportSchedule.reportDateDueAt(
      now ?? DateTime.now(),
    );
    if (reportDate == null) {
      return false;
    }

    final userId = await _storedUserId();
    if (userId == null) {
      return false;
    }

    return await _lastCompletedReportDate(userId) != reportDate;
  }

  static Future<List<InsightReport>> refreshReports({DateTime? now}) async {
    final reportDate = DailyReportSchedule.reportDateDueAt(
      now ?? DateTime.now(),
    );
    if (reportDate == null) {
      return const [];
    }

    final userId = await _storedUserId();
    if (userId == null) {
      return const [];
    }

    if (await _lastCompletedReportDate(userId) == reportDate) {
      return const [];
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.adaptive('/insight-reports/refresh')),
            headers: await ApiConfig.jsonHeaders(),
            body: jsonEncode({'user_id': userId, 'date': reportDate}),
          )
          .timeout(_refreshTimeout);
      final data = _decodeResponseMap(response);
      if (response.statusCode != 200) {
        return const [];
      }

      final reports = _reportsFromData(data);
      final hasDailyReport = reports.any(
        (report) =>
            report.reportType == 'daily' && report.periodStart == reportDate,
      );
      if (hasDailyReport) {
        await OfflineCacheStore.saveJson(
          namespace: scheduledInsightReportGenerationCacheNamespace,
          scope: userId.toString(),
          data: {'completed_report_date': reportDate},
        );
      }
      return reports;
    } catch (_) {
      return const [];
    }
  }

  static Future<String?> _lastCompletedReportDate(int userId) async {
    await OfflineCacheStore.reload();
    final data = await OfflineCacheStore.readLatestJson(
      namespace: scheduledInsightReportGenerationCacheNamespace,
      scope: userId.toString(),
    );
    return data?['completed_report_date']?.toString();
  }

  static Future<int?> _storedUserId() async {
    final session = await UserSessionController.instance.load();
    final userId = session.userId;
    return userId == null || userId <= 0 ? null : userId;
  }

  static Future<List<InsightReport>> _readCachedReports(int userId) async {
    final data = await OfflineCacheStore.readLatestJson(
      namespace: _reportsCache,
      scope: userId.toString(),
    );
    if (data == null) {
      return const [];
    }

    return _reportsFromData(data);
  }

  static List<InsightReport> _reportsFromData(Map<String, dynamic> data) {
    return (data['reports'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => InsightReport.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Map<String, dynamic> _decodeResponseMap(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return const {};
    }

    return const {};
  }
}

int _parseInt(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

DateTime _parseDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

String _dateOnly(dynamic value) {
  final text = value?.toString() ?? '';
  return text.length >= 10 ? text.substring(0, 10) : text;
}

Map<String, dynamic> _mapFromJson(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}
