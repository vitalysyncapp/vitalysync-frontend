import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'assessment_models.dart';

class AssessmentDraft {
  final AssessmentDefinition definition;
  final Map<String, int> answers;
  const AssessmentDraft(this.definition, this.answers);
}

class PendingAssessment {
  final AssessmentSubmission submission;
  final Map<String, dynamic>? onboardingProfile;
  final String? error;
  final int attempts;
  final DateTime? retryAt;
  const PendingAssessment(
    this.submission, {
    this.onboardingProfile,
    this.error,
    this.attempts = 0,
    this.retryAt,
  });

  Map<String, dynamic> toJson() => {
    'submission': submission.toJson(),
    'profile': onboardingProfile,
    'error': error,
    'attempts': attempts,
    'retry_at': retryAt?.toUtc().toIso8601String(),
  };
  factory PendingAssessment.fromJson(Map<String, dynamic> json) =>
      PendingAssessment(
        AssessmentSubmission.fromJson(
          Map<String, dynamic>.from(json['submission'] as Map),
        ),
        onboardingProfile: json['profile'] is Map
            ? Map<String, dynamic>.from(json['profile'] as Map)
            : null,
        error: json['error'] as String?,
        attempts: json['attempts'] as int? ?? 0,
        retryAt: DateTime.tryParse(json['retry_at']?.toString() ?? ''),
      );
}

class AssessmentStore {
  static const prefix = 'cbi_assessment_v1_';
  static final instance = AssessmentStore();
  static Future<void>? _writes;

  Future<void> clearLocalData() async {
    // Drain existing mutations before privacy cleanup. New mutations require an
    // active account, which SessionResetService clears before this call.
    final writes = _writes;
    if (writes != null) await writes;
    final prefs = await SharedPreferences.getInstance();
    for (final key
        in prefs.getKeys().where((key) => key.startsWith(prefix)).toList()) {
      await prefs.remove(key);
    }
  }

  String _key(int userId, String kind) => '$prefix${userId}_$kind';
  Future<T> _write<T>(
    int userId,
    Future<T> Function(SharedPreferences) action,
  ) {
    final next = (_writes ?? Future<void>.value()).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getInt('user_id') != userId) {
        throw StateError('Assessment storage requires the active account.');
      }
      return action(prefs);
    });
    // Keep only active work. Retaining a completed future also retains its
    // scheduling zone, which can stall cleanup after that zone has ended.
    late final Future<void> drained;
    void finished() {
      if (identical(_writes, drained)) _writes = null;
    }

    drained = next.then<void>(
      (_) {
        finished();
      },
      onError: (Object _, StackTrace _) {
        finished();
      },
    );
    _writes = drained;
    return next;
  }

  Future<Map<String, dynamic>?> _read(int userId, String kind) async {
    final writes = _writes;
    if (writes != null) await writes;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId, kind));
    if (raw == null) return null;
    // Corrupt sensitive data stays available for explicit review/cleanup; never
    // silently discard a queue or turn an invalid record into a neutral answer.
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

  Future<void> cacheDefinition(int userId, AssessmentDefinition definition) =>
      _write(userId, (prefs) async {
        await prefs.setString(
          _key(userId, 'definition_${definition.version}'),
          jsonEncode(definition.toJson()),
        );
        await prefs.setString(
          _key(userId, 'definition'),
          jsonEncode(definition.toJson()),
        );
      });

  Future<AssessmentDefinition?> definition(int userId) async {
    final json = await _read(userId, 'definition');
    return json == null ? null : AssessmentDefinition.fromJson(json);
  }

  Future<void> saveDraft(
    int userId,
    AssessmentDefinition definition,
    Map<String, int> answers, {
    bool onboarding = false,
  }) {
    final encoded = jsonEncode({
      'definition': definition.toJson(),
      'answers': answers,
    });
    return _write(userId, (prefs) async {
      await prefs.setString(
        _key(userId, onboarding ? 'onboarding_draft' : 'draft'),
        encoded,
      );
    });
  }

  Future<AssessmentDraft?> draft(int userId, {bool onboarding = false}) async {
    final json = await _read(userId, onboarding ? 'onboarding_draft' : 'draft');
    return json == null
        ? null
        : AssessmentDraft(
            AssessmentDefinition.fromJson(
              Map<String, dynamic>.from(json['definition'] as Map),
            ),
            Map<String, int>.from(json['answers'] as Map),
          );
  }

  Future<void> clearDraft(int userId, {bool onboarding = false}) =>
      _write(userId, (prefs) async {
        await prefs.remove(
          _key(userId, onboarding ? 'onboarding_draft' : 'draft'),
        );
      });

  List<PendingAssessment> _pending(SharedPreferences prefs, int userId) {
    final raw = prefs.getString(_key(userId, 'pending'));
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map(
          (item) => PendingAssessment.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<List<PendingAssessment>> pending(int userId) async {
    final writes = _writes;
    if (writes != null) await writes;
    return _pending(await SharedPreferences.getInstance(), userId);
  }

  Future<void> queue(int userId, PendingAssessment pending) =>
      _write(userId, (prefs) async {
        final items = _pending(prefs, userId);
        final existing = items.where(
          (item) => item.submission.id == pending.submission.id,
        );
        if (existing.isNotEmpty) {
          if (jsonEncode(existing.first.submission.toJson()) !=
                  jsonEncode(pending.submission.toJson()) ||
              jsonEncode(existing.first.onboardingProfile) !=
                  jsonEncode(pending.onboardingProfile)) {
            throw StateError('A completed submission cannot be changed.');
          }
          return;
        }
        items.add(pending);
        await prefs.setString(
          _key(userId, 'pending'),
          jsonEncode(items.map((item) => item.toJson()).toList()),
        );
      });

  Future<void> updatePending(
    int userId,
    String id, {
    String? error,
    int attempts = 0,
    DateTime? retryAt,
    bool remove = false,
  }) => _write(userId, (prefs) async {
    final items = _pending(prefs, userId);
    final updated = <PendingAssessment>[];
    for (final item in items) {
      if (item.submission.id != id) {
        updated.add(item);
      } else if (!remove) {
        updated.add(
          PendingAssessment(
            item.submission,
            onboardingProfile: item.onboardingProfile,
            error: error,
            attempts: attempts,
            retryAt: retryAt,
          ),
        );
      }
    }
    await prefs.setString(
      _key(userId, 'pending'),
      jsonEncode(updated.map((item) => item.toJson()).toList()),
    );
  });

  Future<void> cacheLatest(int userId, AssessmentRecord? record) =>
      _write(userId, (prefs) async {
        if (record == null) {
          await prefs.remove(_key(userId, 'latest'));
        } else {
          await prefs.setString(
            _key(userId, 'latest'),
            jsonEncode(record.toJson()),
          );
        }
      });
  Future<AssessmentRecord?> latest(int userId) async {
    final json = await _read(userId, 'latest');
    return json == null ? null : AssessmentRecord.fromJson(json);
  }
}
