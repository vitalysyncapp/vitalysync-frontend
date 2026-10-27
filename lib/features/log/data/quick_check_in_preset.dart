import 'package:flutter/foundation.dart';

import 'check_in_models.dart';

@immutable
class QuickCheckInAvatar {
  const QuickCheckInAvatar({
    required this.id,
    required this.assetPath,
    required this.semanticLabel,
  });

  final String id;
  final String assetPath;
  final String semanticLabel;
}

class QuickCheckInAvatarCatalog {
  QuickCheckInAvatarCatalog._();

  static const entries = <QuickCheckInAvatar>[
    QuickCheckInAvatar(
      id: 'tired',
      assetPath: 'assets/images/check_in_avatars/1F62B.svg',
      semanticLabel: 'Tired face',
    ),
    QuickCheckInAvatar(
      id: 'sad',
      assetPath: 'assets/images/check_in_avatars/1F614.svg',
      semanticLabel: 'Sad face',
    ),
    QuickCheckInAvatar(
      id: 'neutral',
      assetPath: 'assets/images/check_in_avatars/1F610.svg',
      semanticLabel: 'Neutral face',
    ),
    QuickCheckInAvatar(
      id: 'calm',
      assetPath: 'assets/images/check_in_avatars/1F642.svg',
      semanticLabel: 'Calm face',
    ),
    QuickCheckInAvatar(
      id: 'happy',
      assetPath: 'assets/images/check_in_avatars/1F60A.svg',
      semanticLabel: 'Happy face',
    ),
    QuickCheckInAvatar(
      id: 'celebrating',
      assetPath: 'assets/images/check_in_avatars/1F973.svg',
      semanticLabel: 'Celebrating face',
    ),
    QuickCheckInAvatar(
      id: 'focused',
      assetPath: 'assets/images/check_in_avatars/1F913.svg',
      semanticLabel: 'Focused face',
    ),
    QuickCheckInAvatar(
      id: 'sleepy',
      assetPath: 'assets/images/check_in_avatars/1F971.svg',
      semanticLabel: 'Sleepy face',
    ),
    QuickCheckInAvatar(
      id: 'loved',
      assetPath: 'assets/images/check_in_avatars/1F970.svg',
      semanticLabel: 'Loved face',
    ),
    QuickCheckInAvatar(
      id: 'relieved',
      assetPath: 'assets/images/check_in_avatars/1F60C.svg',
      semanticLabel: 'Relieved face',
    ),
    QuickCheckInAvatar(
      id: 'anxious',
      assetPath: 'assets/images/check_in_avatars/1F630.svg',
      semanticLabel: 'Anxious face',
    ),
    QuickCheckInAvatar(
      id: 'energized',
      assetPath: 'assets/images/check_in_avatars/1F680.svg',
      semanticLabel: 'Energized rocket',
    ),
  ];

  static QuickCheckInAvatar find(String id) {
    return entries.firstWhere(
      (entry) => entry.id == id,
      orElse: () => entries.first,
    );
  }
}

@immutable
class QuickCheckInPreset {
  const QuickCheckInPreset({
    required this.presetId,
    required this.name,
    required this.mode,
    required this.avatarId,
    required this.draft,
    this.weeklyAnswers = const {},
    this.createdAt,
    this.updatedAt,
  });

  final int presetId;
  final String name;
  final CheckInMode mode;
  final String avatarId;
  final CheckInDraft draft;
  final Map<String, int> weeklyAnswers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory QuickCheckInPreset.fromJson(Map<String, dynamic> json) {
    final daily = json['daily'];
    final weekly = json['weekly_answers'];
    return QuickCheckInPreset(
      presetId: _intValue(json['preset_id']),
      name: json['name']?.toString().trim() ?? '',
      mode: CheckInMode.fromValue(json['check_in_type']),
      avatarId: json['avatar_id']?.toString() ?? 'tired',
      draft: CheckInDraft.fromJson(
        daily: daily is Map ? Map<String, dynamic>.from(daily) : null,
      ),
      weeklyAnswers: weekly is Map
          ? weekly.map(
              (key, value) => MapEntry(key.toString(), _intValue(value)),
            )
          : const {},
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
    'preset_id': presetId,
    'name': name,
    'check_in_type': mode.apiValue,
    'avatar_id': avatarId,
    'daily': draft.dailyJson(mode: mode),
    'weekly_answers': mode == CheckInMode.weekly ? weeklyAnswers : null,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  Map<String, dynamic> toMutationJson() => {
    'name': name.trim(),
    'check_in_type': mode.apiValue,
    'avatar_id': avatarId,
    'daily': draft.dailyJson(mode: mode),
    'weekly_answers': mode == CheckInMode.weekly ? weeklyAnswers : null,
  };
}

int _intValue(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
