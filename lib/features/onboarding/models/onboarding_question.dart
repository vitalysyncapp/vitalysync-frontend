class OnboardingQuestion {
  final String title;
  final String field;
  final List<String> options;
  final String? helperText;

  const OnboardingQuestion({
    required this.title,
    required this.field,
    required this.options,
    this.helperText,
  });
}

class LikertOption {
  final int value;
  final String label;

  const LikertOption({required this.value, required this.label});
}

class BurnoutQuestion {
  final String questionKey;
  final String questionText;
  final String category;
  final bool isReverseScored;

  const BurnoutQuestion({
    required this.questionKey,
    required this.questionText,
    required this.category,
    this.isReverseScored = false,
  });

  Map<String, dynamic> toPayload(int numericValue) {
    return {
      'question_key': questionKey,
      'question_text': questionText,
      'category': category,
      'answer_value': numericValue.toString(),
      'numeric_value': numericValue,
      'is_reverse_scored': isReverseScored,
    };
  }
}

class BurnoutSection {
  final String title;
  final String category;
  final List<BurnoutQuestion> questions;

  const BurnoutSection({
    required this.title,
    required this.category,
    required this.questions,
  });
}
