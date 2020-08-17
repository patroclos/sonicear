export 'music_background_task.dart';
export 'playable_song.dart';
export 'playback_utils.dart';

import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class AudioServiceLoopMode {
  static BehaviorSubject<LoopMode> _controller;

  static LoopMode get loopMode => _controller?.value;

  static StreamSubscription _subscription;

  static Stream<LoopMode> get loopModeStream {
    if (_controller == null) connect();

    return _controller.stream;
  }

  static void connect() {
    if (_controller != null) disconnect();

    _controller = BehaviorSubject<LoopMode>();
    _subscription = AudioService.customEventStream
        .where((event) => event['name'] == 'loopmode-changed')
        .map((event) => event['mode'])
        .map(
          (mode) => LoopMode.values.firstWhere((lm) => lm.toString() == mode),
        )
        .listen(_controller.add);
  }

  static void disconnect() {
    _controller.close();
    _subscription.cancel();
    _subscription = null;
    _controller = null;
  }
}
