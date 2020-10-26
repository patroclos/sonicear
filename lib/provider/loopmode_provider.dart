import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class LoopModeProvider with ChangeNotifier {
  LoopMode _mode;

  LoopMode get mode => _mode;

  StreamSubscription _subscription;

  LoopModeProvider() {
    _subscription = AudioService.customEventStream
        .where((event) => event['name'] == 'loopmode-changed')
        .map((event) => event['mode'])
        .map((mode) =>
        LoopMode.values.firstWhere((lm) => lm.toString() == mode))
        .listen((v) {
      _mode = v;
      notifyListeners();
    });
  }

  @override
  dispose() {
    super.dispose();
    _subscription?.cancel();
  }
}

