import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sonicear/audio/audio.dart';

MediaControl _playCtrl = MediaControl(
  androidIcon: 'drawable/ic_action_play_arrow',
  label: 'Play',
  action: MediaAction.play,
);

MediaControl _pauseCtrl = MediaControl(
  androidIcon: 'drawable/ic_action_pause',
  label: 'Pause',
  action: MediaAction.pause,
);

MediaControl _skipNextCtrl = MediaControl(
  androidIcon: 'drawable/ic_action_skip_next',
  label: 'Next',
  action: MediaAction.skipToNext,
);

MediaControl _skipPrevCtrl = MediaControl(
  androidIcon: 'drawable/ic_action_skip_previous',
  label: 'Previous',
  action: MediaAction.skipToPrevious,
);

/*
MediaControl _stopCtrl = MediaControl(
  androidIcon: 'drawable/ic_action_stop',
  label: 'Stop',
  action: MediaAction.stop,
);
 */

class MusicBackgroundTask extends BackgroundAudioTask {
  AudioPlayer _player = AudioPlayer();
  ConcatenatingAudioSource _audioSource =
      ConcatenatingAudioSource(children: []);

  List<MediaControl> get controls => (_playing ?? false)
      ? [
          _skipPrevCtrl,
          _pauseCtrl,
          // _stopCtrl,
          _skipNextCtrl,
        ]
      : [
          _skipPrevCtrl,
          _playCtrl,
          // _stopCtrl,
          _skipNextCtrl,
        ];

  int _queueIndex = -1;
  bool _playing;
  // bool _interrupted = false;
  AudioProcessingState _skipState;

  final _queue = <MediaItem>[];

  bool get hasNext => _queueIndex + 1 < _queue.length;

  bool get hasPrev => _queueIndex > 0;

  MediaItem get mediaItem => _queueIndex == -1 ? null : _queue[_queueIndex];

  StreamSubscription<PlayerState> _playerStateSub;
  StreamSubscription<PlaybackEvent> _eventSub;
  StreamSubscription<SequenceState> _sequenceSub;

  Future<void> _setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
    print('Set LoopMode to $mode');
    AudioServiceBackground.sendCustomEvent({'name': 'loopmode-changed', 'mode': mode.toString()});
  }

  @override
  Future<dynamic> onCustomAction(String name, arguments) async {
    switch (name) {
      case 'set-loopmode':
        await _setLoopMode(LoopMode.values.firstWhere((lm) => lm.toString() == arguments));
        break;
      default:
        throw Exception('Unknown custom audio service action: $name');
    }
  }

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    _playerStateSub = _player.playerStateStream
        .where((event) =>
            event.playing && event.processingState == ProcessingState.completed)
        .listen(
      (event) {
        _handlePlaybackCompleted();
      },
    );

    _sequenceSub = _player.sequenceStateStream.listen((state) {
      if(state == null)
        return;
      if (_queueIndex != state.currentIndex) {
        _queueIndex = state.currentIndex;
        AudioServiceBackground.setMediaItem(mediaItem);
      }
      AudioServiceBackground.setQueue(_queue.skip(_queueIndex + 1).toList());
    });

    _eventSub = _player.playbackEventStream.listen(
      (event) {
        final isBuffering = event.processingState == ProcessingState.buffering;
        final bufferState = isBuffering ? AudioProcessingState.buffering : null;

        _setState(
          processingState: bufferState ?? AudioProcessingState.ready,
          position: _player.position,
        );
      },
    );

    await _player.load(_audioSource);
    _setLoopMode(LoopMode.all);
  }

  Future _setState({
    AudioProcessingState processingState,
    Duration position,
    Duration bufferedPosition,
  }) async {
    position = position ?? _player.position;

    await AudioServiceBackground.setState(
      controls: controls,
      systemActions: [MediaAction.seekTo],
      processingState:
          processingState ?? AudioServiceBackground.state.processingState,
      playing: _playing ?? false,
      position: position,
      bufferedPosition: bufferedPosition ?? _player.bufferedPosition,
      speed: _player.speed,
    );
  }

  void _handlePlaybackCompleted() {
    // onStop();
    // TODO: we're not stopping here atm, since this gets triggered pretty early bc of the empty concatenation source
  }

  @override
  Future<void> onSkipToNext() => _skip(1);

  @override
  Future<void> onSkipToPrevious() => _skip(-1);

  @override
  Future<void> onSkipToQueueItem(String mediaId) async {
    final idx = _queue.indexWhere((item) => item.id == mediaId);
    _skip(idx - _queueIndex);
  }

  Future<void> _skip(int offset) async {
    final newPos = _queueIndex + offset;
    if (newPos < 0 || newPos >= _queue.length) return;
    if (_playing == null)
      _playing = true;

    _skipState = offset > 0
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    await _player.seek(Duration.zero, index: newPos);
    _skipState = null;

    if (_playing)
      onPlay();
    else
      _setState(processingState: AudioProcessingState.ready);
  }

  @override
  Future<void> onPlay() async {
    if (_skipState == null) {
      _playing = true;
      _player.play();
    }
  }

  @override
  Future<void> onPause() async {
    if (_skipState == null) {
      _playing = false;
      _player.pause();
    }
  }

  @override
  Future<void> onSeekTo(Duration position) async{
    _player.seek(position);
  }

  @override
  Future<void> onClick(MediaButton button)async {
    playPause();
  }

  @override
  Future<void> onTaskRemoved() async {
    await onStop();
    return super.onTaskRemoved();
  }

  @override
  Future<void> onStop() async {
    await _player.stop();
    await _player.dispose();
    _playing = false;
    _playerStateSub.cancel();
    _eventSub.cancel();
    _sequenceSub.cancel();
    await _setState(processingState: AudioProcessingState.stopped);
    await super.onStop();
  }

  /*
  @override
  void onAudioFocusLost(AudioInterruption interruption) {
    if (_playing) _interrupted = true;
    switch (interruption) {
      case AudioInterruption.pause:
      case AudioInterruption.temporaryPause:
      case AudioInterruption.unknownPause:
        onPause();
        break;
      case AudioInterruption.temporaryDuck:
        _player.setVolume(.5);
        break;
    }
  }

  @override
  void onAudioFocusGained(AudioInterruption interruption) {
    switch (interruption) {
      case AudioInterruption.temporaryPause:
        if (!_playing && _interrupted) onPlay();
        break;
      case AudioInterruption.temporaryDuck:
        _player.setVolume(1.0);
        break;
      default:
        break;
    }
    _interrupted = false;
  }
   */

  @override
  Future<void> onAudioBecomingNoisy() async {
    onPause();
  }

  void playPause() {
    if (AudioServiceBackground.state.playing)
      onPause();
    else
      onPlay();
  }

  @override
  Future<void> onPlayMediaItem(MediaItem mediaItem) async {
    final insertIdx = _queueIndex == -1 ? 0 : (_queueIndex + 1);
    _queue.insert(insertIdx, mediaItem);
    await _audioSource.insert(
      insertIdx,
      AudioSource.uri(
        Uri.parse(mediaItem.extras[kStreamUrl]),
      ),
    );

    onSkipToNext();
  }

  @override
  Future<void> onAddQueueItem(MediaItem mediaItem) async {
    _queue.add(mediaItem);
    await _audioSource.add(
      AudioSource.uri(
        Uri.parse(mediaItem.extras[kStreamUrl]),
      ),
    );
  }

  @override
  Future<void> onAddQueueItemAt(MediaItem mediaItem, int index) async {
    _queue.insert(index + _queueIndex, mediaItem);
    await _audioSource.insert(
      index + _queueIndex,
      AudioSource.uri(
        Uri.parse(mediaItem.extras[kStreamUrl]),
      ),
    );
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> queue) async {
    _queue.clear();
    _queue.addAll(queue);

    final size = _audioSource.length;
    await _audioSource.addAll((queue.map(_sourceFromItem)).toList());
    if(size > 0)
      _audioSource.removeRange(0, size);
  }

  AudioSource _sourceFromItem(MediaItem item) {
    return AudioSource.uri(Uri.parse(item.extras[kStreamUrl]));
  }
}

void _taskEntrypoint() async {
  AudioServiceBackground.run(() => MusicBackgroundTask());
}

Future<bool> startSonicearAudioTask() {
  return AudioService.start(
    backgroundTaskEntrypoint: _taskEntrypoint,
    androidNotificationChannelName: 'SonicEar Playback',
    androidNotificationColor: Colors.green.value,
    androidNotificationIcon: 'mipmap/ic_launcher',
    androidEnableQueue: true,
  );
}
