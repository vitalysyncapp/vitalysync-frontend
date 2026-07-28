import 'package:flutter/foundation.dart';

@immutable
class CheckInStateChange {
  final Object source;
  final int revision;

  const CheckInStateChange({required this.source, required this.revision});
}

class CheckInStateCoordinator {
  CheckInStateCoordinator._();

  static final CheckInStateCoordinator instance = CheckInStateCoordinator._();

  final ValueNotifier<CheckInStateChange?> changes =
      ValueNotifier<CheckInStateChange?>(null);

  void markChanged(Object source) {
    changes.value = CheckInStateChange(
      source: source,
      revision: (changes.value?.revision ?? 0) + 1,
    );
  }
}
