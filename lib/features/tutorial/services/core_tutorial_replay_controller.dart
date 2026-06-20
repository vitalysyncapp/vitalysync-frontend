import 'package:flutter/foundation.dart';

class CoreTutorialReplayController {
  CoreTutorialReplayController._();

  static final CoreTutorialReplayController instance =
      CoreTutorialReplayController._();

  final ValueNotifier<int> requests = ValueNotifier<int>(0);

  void requestReplay() {
    requests.value++;
  }
}
