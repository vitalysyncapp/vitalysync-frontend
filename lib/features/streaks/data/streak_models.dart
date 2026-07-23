import '../../../features/log/data/log_api.dart';

class StreakSnapshot {
  final int currentStreak;
  final int longestStreak;
  final String? lastLoggedDate;

  const StreakSnapshot({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastLoggedDate,
  });

  factory StreakSnapshot.fromJson(Map<String, dynamic>? json) {
    return StreakSnapshot(
      currentStreak: LogApi.parseInt(json?['current_streak']),
      longestStreak: LogApi.parseInt(json?['longest_streak']),
      lastLoggedDate: LogApi.normalizeDateString(json?['last_logged_date']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_logged_date': lastLoggedDate,
    };
  }
}

class StreakSavers {
  final String? periodMonth;
  final int baseSavers;
  final int earnedSavers;
  final int usedSavers;
  final int availableSavers;

  const StreakSavers({
    required this.periodMonth,
    required this.baseSavers,
    required this.earnedSavers,
    required this.usedSavers,
    required this.availableSavers,
  });

  factory StreakSavers.fromJson(Map<String, dynamic>? json) {
    return StreakSavers(
      periodMonth: LogApi.normalizeDateString(json?['period_month']),
      baseSavers: LogApi.parseInt(json?['base_savers'], fallback: 3),
      earnedSavers: LogApi.parseInt(json?['earned_savers']),
      usedSavers: LogApi.parseInt(json?['used_savers']),
      availableSavers: LogApi.parseInt(json?['available_savers'], fallback: 3),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'period_month': periodMonth,
      'base_savers': baseSavers,
      'earned_savers': earnedSavers,
      'used_savers': usedSavers,
      'available_savers': availableSavers,
    };
  }
}

class StreakEvent {
  final String type;
  final int amount;
  final String reason;
  final String? protectedDate;
  final String? createdAt;

  const StreakEvent({
    required this.type,
    required this.amount,
    required this.reason,
    required this.protectedDate,
    required this.createdAt,
  });

  factory StreakEvent.fromJson(Map<String, dynamic> json) {
    return StreakEvent(
      type: json['event_type']?.toString() ?? '',
      amount: LogApi.parseInt(json['amount']),
      reason: json['reason']?.toString() ?? '',
      protectedDate: LogApi.normalizeDateString(json['protected_date']),
      createdAt: json['created_at']?.toString(),
    );
  }
}

class StreakOverview {
  final int userId;
  final String displayName;
  final StreakSnapshot streak;
  final StreakSavers savers;
  final int protectedDayCount;
  final List<StreakEvent> recentEvents;
  final bool isOffline;

  const StreakOverview({
    required this.userId,
    required this.displayName,
    required this.streak,
    required this.savers,
    required this.protectedDayCount,
    required this.recentEvents,
    this.isOffline = false,
  });

  factory StreakOverview.fromJson(
    Map<String, dynamic> json, {
    bool isOffline = false,
  }) {
    final rawEvents = json['recent_events'] as List<dynamic>? ?? const [];

    return StreakOverview(
      userId: LogApi.parseInt(json['user_id']),
      displayName: json['display_name']?.toString() ?? 'VitalySync user',
      streak: StreakSnapshot.fromJson(
        json['streak'] is Map
            ? Map<String, dynamic>.from(json['streak'] as Map)
            : null,
      ),
      savers: StreakSavers.fromJson(
        json['savers'] is Map
            ? Map<String, dynamic>.from(json['savers'] as Map)
            : null,
      ),
      protectedDayCount: LogApi.parseInt(json['protected_day_count']),
      recentEvents: rawEvents
          .whereType<Map>()
          .map((item) => StreakEvent.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      isOffline: isOffline,
    );
  }
}

class StreakLeaderboardRow {
  final int rank;
  final int userId;
  final String displayName;
  final String initials;
  final String avatarColor;
  final String? gender;
  final String? userType;
  final String avatarAsset;
  final int score;
  final int protectedDayCount;
  final bool isCurrentUser;

  const StreakLeaderboardRow({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.initials,
    required this.avatarColor,
    this.gender,
    this.userType,
    this.avatarAsset = '',
    required this.score,
    required this.protectedDayCount,
    required this.isCurrentUser,
  });

  factory StreakLeaderboardRow.fromJson(Map<String, dynamic> json) {
    return StreakLeaderboardRow(
      rank: LogApi.parseInt(json['rank']),
      userId: LogApi.parseInt(json['user_id']),
      displayName: json['display_name']?.toString() ?? 'VitalySync user',
      initials: json['initials']?.toString() ?? 'VS',
      avatarColor: json['avatar_color']?.toString() ?? '#1D8CA8',
      gender: _optionalText(json['gender']),
      userType: _optionalText(json['user_type'] ?? json['role']),
      avatarAsset: json['avatar_asset']?.toString() ?? '',
      score: LogApi.parseInt(json['score']),
      protectedDayCount: LogApi.parseInt(json['protected_day_count']),
      isCurrentUser: json['is_current_user'] == true,
    );
  }
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

class StreakLeaderboard {
  final String section;
  final String metric;
  final bool available;
  final String sectionLabel;
  final int? currentUserRank;
  final List<StreakLeaderboardRow> rows;

  const StreakLeaderboard({
    required this.section,
    required this.metric,
    required this.available,
    required this.sectionLabel,
    required this.currentUserRank,
    required this.rows,
  });

  factory StreakLeaderboard.fromJson(Map<String, dynamic> json) {
    final rawRows = json['rows'] as List<dynamic>? ?? const [];

    return StreakLeaderboard(
      section: json['section']?.toString() ?? 'global',
      metric: json['metric']?.toString() ?? 'current',
      available: json['available'] != false,
      sectionLabel: json['section_label']?.toString() ?? 'Global',
      currentUserRank: json['current_user_rank'] == null
          ? null
          : LogApi.parseInt(json['current_user_rank']),
      rows: rawRows
          .whereType<Map>()
          .map(
            (item) =>
                StreakLeaderboardRow.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class StreakRestoreDetails {
  final bool required;
  final String reason;
  final int missingDays;
  final int availableSavers;
  final int saversRequired;
  final List<String> missingDates;

  const StreakRestoreDetails({
    required this.required,
    required this.reason,
    required this.missingDays,
    required this.availableSavers,
    required this.saversRequired,
    required this.missingDates,
  });

  factory StreakRestoreDetails.fromJson(Map<String, dynamic> json) {
    final rawDates = json['missing_dates'] as List<dynamic>? ?? const [];

    return StreakRestoreDetails(
      required: json['required'] == true,
      reason: json['reason']?.toString() ?? 'missed_days',
      missingDays: LogApi.parseInt(json['missing_days']),
      availableSavers: LogApi.parseInt(json['available_savers']),
      saversRequired: LogApi.parseInt(json['savers_required']),
      missingDates: rawDates
          .map((date) => LogApi.normalizeDateString(date))
          .whereType<String>()
          .toList(),
    );
  }
}
