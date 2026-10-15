import '../models/onboarding_question.dart';

const kBurnoutQuestionnaireVersion = 'vitalysync_maslach22_v1';
const kWeeklyQuestionnaireVersion = 'vitalysync_maslach11_v1';
const kWeeklyQuestionCount = 11;

final kBurnoutWeeklySections = List<BurnoutSection>.unmodifiable([
  for (final section in kBurnoutBaselineSections)
    BurnoutSection(
      title: section.title,
      category: section.category,
      questions: List<BurnoutQuestion>.unmodifiable(
        section.questions.take(
          section.category == 'emotional_exhaustion' ? 5 : 3,
        ),
      ),
    ),
]);

const kBurnoutBaselineScale = [
  LikertOption(value: 1, label: 'Never'),
  LikertOption(value: 2, label: 'Rarely'),
  LikertOption(value: 3, label: 'Sometimes'),
  LikertOption(value: 4, label: 'Often'),
  LikertOption(value: 5, label: 'Always'),
];

const kBurnoutBaselineSections = [
  BurnoutSection(
    title: '\u{1F635} Emotional exhaustion',
    category: 'emotional_exhaustion',
    questions: [
      BurnoutQuestion(
        questionKey: 'ee_01',
        questionText:
            'I feel emotionally drained by my daily responsibilities.',
        category: 'emotional_exhaustion',
      ),
      BurnoutQuestion(
        questionKey: 'ee_02',
        questionText: 'I feel tired even before starting my day.',
        category: 'emotional_exhaustion',
      ),
      BurnoutQuestion(
        questionKey: 'ee_03',
        questionText: 'I feel overwhelmed by my tasks.',
        category: 'emotional_exhaustion',
      ),
      BurnoutQuestion(
        questionKey: 'ee_04',
        questionText: 'I feel fatigued most of the time.',
        category: 'emotional_exhaustion',
      ),
      BurnoutQuestion(
        questionKey: 'ee_05',
        questionText: 'I feel I have no energy left at the end of the day.',
        category: 'emotional_exhaustion',
      ),
      BurnoutQuestion(
        questionKey: 'ee_06',
        questionText: 'I feel worn out after dealing with everyday demands.',
        category: 'emotional_exhaustion',
      ),
      BurnoutQuestion(
        questionKey: 'ee_07',
        questionText:
            'I find it tiring to keep up with what is expected of me.',
        category: 'emotional_exhaustion',
      ),
      BurnoutQuestion(
        questionKey: 'ee_08',
        questionText: 'I feel emotionally spent when another task comes up.',
        category: 'emotional_exhaustion',
      ),
      BurnoutQuestion(
        questionKey: 'ee_09',
        questionText:
            'I feel that my responsibilities use up my emotional strength.',
        category: 'emotional_exhaustion',
      ),
    ],
  ),
  BurnoutSection(
    title: '\u{1F9CA} Detachment',
    category: 'depersonalization',
    questions: [
      BurnoutQuestion(
        questionKey: 'dp_01',
        questionText: 'I feel detached from my responsibilities.',
        category: 'depersonalization',
      ),
      BurnoutQuestion(
        questionKey: 'dp_02',
        questionText:
            'I have become less interested in things I used to enjoy.',
        category: 'depersonalization',
      ),
      BurnoutQuestion(
        questionKey: 'dp_03',
        questionText: 'I feel indifferent toward my tasks.',
        category: 'depersonalization',
      ),
      BurnoutQuestion(
        questionKey: 'dp_04',
        questionText: 'I feel less emotionally connected to others.',
        category: 'depersonalization',
      ),
      BurnoutQuestion(
        questionKey: 'dp_05',
        questionText:
            "I sometimes feel like I'm just going through the motions.",
        category: 'depersonalization',
      ),
    ],
  ),
  BurnoutSection(
    title: '\u{1F3C6} Personal accomplishment',
    category: 'personal_accomplishment',
    questions: [
      BurnoutQuestion(
        questionKey: 'pa_01',
        questionText: 'I feel productive in my daily life.',
        category: 'personal_accomplishment',
        isReverseScored: true,
      ),
      BurnoutQuestion(
        questionKey: 'pa_02',
        questionText: 'I feel I am achieving meaningful results.',
        category: 'personal_accomplishment',
        isReverseScored: true,
      ),
      BurnoutQuestion(
        questionKey: 'pa_03',
        questionText: 'I feel confident handling my responsibilities.',
        category: 'personal_accomplishment',
        isReverseScored: true,
      ),
      BurnoutQuestion(
        questionKey: 'pa_04',
        questionText: 'I feel motivated to accomplish my goals.',
        category: 'personal_accomplishment',
        isReverseScored: true,
      ),
      BurnoutQuestion(
        questionKey: 'pa_05',
        questionText: 'I feel satisfied with what I achieve each day.',
        category: 'personal_accomplishment',
        isReverseScored: true,
      ),
      BurnoutQuestion(
        questionKey: 'pa_06',
        questionText:
            'I can find a useful way forward when a task becomes difficult.',
        category: 'personal_accomplishment',
        isReverseScored: true,
      ),
      BurnoutQuestion(
        questionKey: 'pa_07',
        questionText: 'I feel that my efforts make a positive difference.',
        category: 'personal_accomplishment',
        isReverseScored: true,
      ),
      BurnoutQuestion(
        questionKey: 'pa_08',
        questionText: 'I handle unexpected demands effectively.',
        category: 'personal_accomplishment',
        isReverseScored: true,
      ),
    ],
  ),
];
