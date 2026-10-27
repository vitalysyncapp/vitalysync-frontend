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
      assetPath: 'assets/images/check_in_avatars/noto_tired.svg',
      semanticLabel: 'Tired',
    ),
    QuickCheckInAvatar(
      id: 'sad',
      assetPath: 'assets/images/check_in_avatars/noto_sad.svg',
      semanticLabel: 'Sad',
    ),
    QuickCheckInAvatar(
      id: 'neutral',
      assetPath: 'assets/images/check_in_avatars/noto_neutral.svg',
      semanticLabel: 'Neutral',
    ),
    QuickCheckInAvatar(
      id: 'calm',
      assetPath: 'assets/images/check_in_avatars/noto_calm.svg',
      semanticLabel: 'Calm',
    ),
    QuickCheckInAvatar(
      id: 'happy',
      assetPath: 'assets/images/check_in_avatars/noto_happy.svg',
      semanticLabel: 'Happy',
    ),
    QuickCheckInAvatar(
      id: 'celebrating',
      assetPath: 'assets/images/check_in_avatars/noto_celebrating.svg',
      semanticLabel: 'Celebrating',
    ),
    QuickCheckInAvatar(
      id: 'focused',
      assetPath: 'assets/images/check_in_avatars/noto_focused.svg',
      semanticLabel: 'Focused',
    ),
    QuickCheckInAvatar(
      id: 'sleepy',
      assetPath: 'assets/images/check_in_avatars/noto_sleepy.svg',
      semanticLabel: 'Sleepy',
    ),
    QuickCheckInAvatar(
      id: 'loved',
      assetPath: 'assets/images/check_in_avatars/noto_loved.svg',
      semanticLabel: 'Loved',
    ),
    QuickCheckInAvatar(
      id: 'relieved',
      assetPath: 'assets/images/check_in_avatars/noto_relieved.svg',
      semanticLabel: 'Relaxed',
    ),
    QuickCheckInAvatar(
      id: 'anxious',
      assetPath: 'assets/images/check_in_avatars/noto_anxious.svg',
      semanticLabel: 'Unsure',
    ),
    QuickCheckInAvatar(
      id: 'energized',
      assetPath: 'assets/images/check_in_avatars/noto_energized.svg',
      semanticLabel: 'Energized',
    ),
    QuickCheckInAvatar(
      id: 'productive',
      assetPath: 'assets/images/check_in_avatars/noto_productive.svg',
      semanticLabel: 'Productive',
    ),
    QuickCheckInAvatar(
      id: 'busy',
      assetPath: 'assets/images/check_in_avatars/noto_busy.svg',
      semanticLabel: 'Busy',
    ),
    QuickCheckInAvatar(
      id: 'studying',
      assetPath: 'assets/images/check_in_avatars/noto_studying.svg',
      semanticLabel: 'Studying',
    ),
    QuickCheckInAvatar(
      id: 'creative',
      assetPath: 'assets/images/check_in_avatars/noto_creative.svg',
      semanticLabel: 'Creative',
    ),
    QuickCheckInAvatar(
      id: 'cooking',
      assetPath: 'assets/images/check_in_avatars/noto_cooking.svg',
      semanticLabel: 'Cooking',
    ),
    QuickCheckInAvatar(
      id: 'gardening',
      assetPath: 'assets/images/check_in_avatars/noto_gardening.svg',
      semanticLabel: 'Gardening',
    ),
    QuickCheckInAvatar(
      id: 'caring',
      assetPath: 'assets/images/check_in_avatars/noto_caring.svg',
      semanticLabel: 'Caring',
    ),
    QuickCheckInAvatar(
      id: 'teaching',
      assetPath: 'assets/images/check_in_avatars/noto_teaching.svg',
      semanticLabel: 'Teaching',
    ),
    QuickCheckInAvatar(
      id: 'fixing',
      assetPath: 'assets/images/check_in_avatars/noto_fixing.svg',
      semanticLabel: 'Fixing things',
    ),
    QuickCheckInAvatar(
      id: 'exploring',
      assetPath: 'assets/images/check_in_avatars/noto_exploring.svg',
      semanticLabel: 'Exploring',
    ),
    QuickCheckInAvatar(
      id: 'singing',
      assetPath: 'assets/images/check_in_avatars/noto_singing.svg',
      semanticLabel: 'Singing',
    ),
    QuickCheckInAvatar(
      id: 'dancing',
      assetPath: 'assets/images/check_in_avatars/noto_dancing.svg',
      semanticLabel: 'Dancing',
    ),
    QuickCheckInAvatar(
      id: 'joyful',
      assetPath: 'assets/images/check_in_avatars/noto_joyful.svg',
      semanticLabel: 'Joyful',
    ),
    QuickCheckInAvatar(
      id: 'strong',
      assetPath: 'assets/images/check_in_avatars/noto_strong.svg',
      semanticLabel: 'Strong',
    ),
    QuickCheckInAvatar(
      id: 'stretching',
      assetPath: 'assets/images/check_in_avatars/noto_stretching.svg',
      semanticLabel: 'Stretching',
    ),
    QuickCheckInAvatar(
      id: 'walking',
      assetPath: 'assets/images/check_in_avatars/noto_walking.svg',
      semanticLabel: 'Walking',
    ),
    QuickCheckInAvatar(
      id: 'cycling',
      assetPath: 'assets/images/check_in_avatars/noto_cycling.svg',
      semanticLabel: 'Cycling',
    ),
    QuickCheckInAvatar(
      id: 'swimming',
      assetPath: 'assets/images/check_in_avatars/noto_swimming.svg',
      semanticLabel: 'Swimming',
    ),
    QuickCheckInAvatar(
      id: 'climbing',
      assetPath: 'assets/images/check_in_avatars/noto_climbing.svg',
      semanticLabel: 'Climbing',
    ),
    QuickCheckInAvatar(
      id: 'resting',
      assetPath: 'assets/images/check_in_avatars/noto_resting.svg',
      semanticLabel: 'Resting',
    ),
    QuickCheckInAvatar(
      id: 'mindful',
      assetPath: 'assets/images/check_in_avatars/noto_mindful.svg',
      semanticLabel: 'Mindful',
    ),
    QuickCheckInAvatar(
      id: 'overwhelmed',
      assetPath: 'assets/images/check_in_avatars/noto_overwhelmed.svg',
      semanticLabel: 'Overwhelmed',
    ),
    QuickCheckInAvatar(
      id: 'uncertain',
      assetPath: 'assets/images/check_in_avatars/noto_uncertain.svg',
      semanticLabel: 'Uncertain',
    ),
    QuickCheckInAvatar(
      id: 'unwell',
      assetPath: 'assets/images/check_in_avatars/noto_unwell.svg',
      semanticLabel: 'Unwell',
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
