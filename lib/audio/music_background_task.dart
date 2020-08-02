import 'dart:async';
import 'dart:math';

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

  List<MediaControl> get controls => _playing
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
  bool _interrupted = false;
  AudioProcessingState _skipState;

  final _queue = <MediaItem>[];

  bool get hasNext => _queueIndex + 1 < _queue.length;
  //bool get hasNext => _queue.isNotEmpty;

  bool get hasPrev => _queueIndex > 0;

  MediaItem get mediaItem => _queue[_queueIndex];

  StreamSubscription<AudioPlaybackState> _playerStateSub;
  StreamSubscription<AudioPlaybackEvent> _eventSub;

  @override
  void onStart(Map<String, dynamic> params) {
    _playerStateSub = _player.playbackStateStream
        .where((event) => event == AudioPlaybackState.completed)
        .listen(
      (event) {
        _handlePlaybackCompleted();
      },
    );

    _eventSub = _player.playbackEventStream.listen(
      (event) {
        final bufferState =
            event.buffering ? AudioProcessingState.buffering : null;

        switch (event.state) {
          case AudioPlaybackState.paused:
          case AudioPlaybackState.playing:
            _setState(
              processingState: bufferState ?? AudioProcessingState.ready,
              position: event.position,
            );
            break;
          case AudioPlaybackState.connecting:
            _setState(
              processingState: _skipState ?? AudioProcessingState.connecting,
              position: event.position,
            );
            break;
          default:
            break;
        }
      },
    );

    onSkipToNext();
  }

  Future _setState({
    AudioProcessingState processingState,
    Duration position,
    Duration bufferedPosition,
  }) async {
    position = position ?? _player.playbackEvent.position;

    await AudioServiceBackground.setState(
      controls: controls,
      systemActions: [MediaAction.seekTo],
      processingState:
          processingState ?? AudioServiceBackground.state.processingState,
      playing: _playing ?? false,
      position: position,
      bufferedPosition: bufferedPosition ?? position,
      speed: _player.speed,
    );
  }

  void _handlePlaybackCompleted() {
    if (hasNext)
      onSkipToNext();
    else if (hasPrev){
      // reshuffle, restart
      _queue.sort((a,b)=>Random.secure().nextInt(2) - 1);
      _queueIndex = -1;
      onSkipToNext();
    }
    else
      onStop();
      // onStop();
  }

  @override
  Future<void> onSkipToNext() => _skip(1);

  @override
  Future<void> onSkipToPrevious() => _skip(-1);


  @override
  void onSkipToQueueItem(String mediaId) {
    final idx = _queue.indexWhere((item) => item.id == mediaId);
    _skip(idx - _queueIndex);
  }

  Future<void> _skip(int offset) async {
    final newPos = _queueIndex + offset;
    if (newPos < 0 || newPos >= _queue.length) return;
    if (_playing == null)
      _playing = true;
    else if (_playing) await _player.stop();

    _queueIndex = newPos;

    AudioServiceBackground.setMediaItem(mediaItem);
    _updateQueue();

    _skipState = offset > 0
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;
    await _player.setUrl(mediaItem.extras[kStreamUrl]);
    _skipState = null;


    if (_playing)
      onPlay();
    else
      _setState(processingState: AudioProcessingState.ready);
  }

  @override
  void onPlay() {
    if (_skipState == null) {
      _playing = true;
      _player.play();
    }
  }

  @override
  void onPause() {
    if (_skipState == null) {
      _playing = false;
      _player.pause();
    }
  }

  @override
  void onSeekTo(Duration position) {
    _player.seek(position);
  }

  @override
  void onClick(MediaButton button) {
    playPause();
  }

  @override
  Future<void> onStop() async {
    await _player.stop();
    await _player.dispose();
    _playing = false;
    _playerStateSub.cancel();
    _eventSub.cancel();
    await _setState(processingState: AudioProcessingState.stopped);
    await super.onStop();
  }

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

  @override
  void onAudioBecomingNoisy() {
    onPause();
  }

  void playPause() {
    if (AudioServiceBackground.state.playing)
      onPause();
    else
      onPlay();
  }

  @override
  void onPlayMediaItem(MediaItem mediaItem) {
    /*
    _queue.clear();
    _queueIndex = -1;
    _queue.add(mediaItem);
     */
    if(_queueIndex == -1)
      _queue.insert(0, mediaItem);
    else
      _queue.insert(_queueIndex, mediaItem);
    onSkipToNext();
  }

  @override
  void onAddQueueItem(MediaItem mediaItem) {
    _queue.add(mediaItem);
    _updateQueue();
  }

  @override
  void onAddQueueItemAt(MediaItem mediaItem, int index) {
    _queue.insert(index + _queueIndex, mediaItem);
    _updateQueue();
  }

  void _updateQueue() {
    AudioServiceBackground.setQueue(_queue.skip(_queueIndex + 1).toList());
  }

  @override
  Future<void> onUpdateQueue(List<MediaItem> queue) {
    _queue.clear();
    _queue.addAll(queue);
    _queueIndex=-1;
    // TODO: probably we shouldn't skip yet
    onSkipToNext();

    return Future.value();
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
