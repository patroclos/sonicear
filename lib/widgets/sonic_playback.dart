import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sonicear/audio/audio.dart';
import 'package:sonicear/audio/playback_utils.dart';
import 'package:sonicear/usecases/extensions.dart';
import 'package:sonicear/widgets/app_playback_state.dart';
import 'package:sonicear/widgets/queue_management_screen.dart';
import 'package:sonicear/widgets/song_context_sheet.dart';
import 'package:sonicear/widgets/sonic_cover.dart';

class SonicPlayback extends StatefulWidget {
  @override
  _SonicPlaybackState createState() => _SonicPlaybackState();
}

class _SonicPlaybackState extends State<SonicPlayback> {
  final BehaviorSubject<double> _dragPositionSubject =
      BehaviorSubject.seeded(null);

  @override
  void dispose() {
    super.dispose();
    _dragPositionSubject.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<MediaItem>(
          stream: AudioService.currentMediaItemStream,
          builder: (context, snapshot) => Center(
            child: Text(
              !snapshot.hasData ? 'Not playing Anything' : snapshot.data.title,
              style: Theme.of(context).textTheme.subtitle2,
            ),
          ),
        ),
        actions: [
          StreamBuilder<MediaItem>(
              stream: AudioService.currentMediaItemStream,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return Container();

                return IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () {
                    Scaffold.of(context).showBottomSheet(
                      (context) => SongContextSheet(
                        snapshot.data.extractDbSong(),
                      ),
                    );
                  },
                );
              })
        ],
        leading: IconButton(
          icon: Icon(Icons.keyboard_arrow_down),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StreamBuilder<AppPlaybackState>(
              stream: AppPlaybackState.stateStream,
              builder: (context, snapshot) {
                final screenState = snapshot.data;
                final mediaItem = screenState?.currentSong;
                final state = screenState?.playbackState;
                final playing = state?.playing ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    if (mediaItem?.extras?.containsKey(kCoverId) ?? false)
                      _cover,
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          mediaItem?.title ?? '',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        Text(
                          mediaItem?.artist ?? '',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ],
                    ),
                    if (mediaItem != null) positionScrubber(mediaItem, state),
                    if (AudioService.running) _playbackControlRow(playing),
                    IconButton(
                      icon: Icon(Icons.queue_music),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QueueManagementScreen(),
                          ),
                        );
                      },
                    )
                  ],
                );
              }),
        ),
      ),
    );
  }

  Widget get _cover => StreamBuilder<MediaItem>(
    stream: AudioService.currentMediaItemStream,
    builder: (context, snapshot) {
      return Padding(
            padding: const EdgeInsets.only(
              bottom: 32,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SonicCover(
              snapshot.hasData ? snapshot.data.extras[kCoverId] : null,
              size: MediaQuery.of(context).size.shortestSide / 4 * 3,
            ),
          );
    }
  );

  Widget _playbackControlRow(bool playing) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.shuffle),
            iconSize: 35,
            onPressed: () {
              throw new StateError('not implemented');
            },
          ),
          _prevButton,
          _playPauseButton(playing),
          _nextButton,
          _repeatButton
        ],
      );

  Widget _prevButton = IconButton(
    icon: Icon(Icons.skip_previous),
    onPressed: () async {
      await AudioService.skipToPrevious();
    },
  );

  Widget _nextButton = IconButton(
    icon: Icon(Icons.skip_next),
    onPressed: () async {
      await AudioService.skipToNext();
    },
  );

  Widget _repeatButton = StreamBuilder<LoopMode>(
    stream: AudioServiceLoopMode.loopModeStream,
    builder: (context, snapshot) {
      final order = [
        LoopMode.all,
        LoopMode.one,
        LoopMode.off,
      ];
      final idx =
          order.indexOf(snapshot.hasData ? snapshot.data : LoopMode.all);
      final next = (idx + 1) % order.length;
      final icons = <LoopMode, Icon>{
        LoopMode.off: Icon(Icons.repeat, color: Colors.grey),
        LoopMode.one: Icon(Icons.repeat_one),
        LoopMode.all: Icon(Icons.repeat),
      };

      return IconButton(
        icon: icons[order[idx]],
        iconSize: 35,
        onPressed: () async {
          await AudioService.customAction(
            'set-loopmode',
            order[next].toString(),
          );
        },
      );
    },
  );

  Widget _playPauseButton(bool playing) => IconButton(
        icon: Icon(playing ? Icons.pause : Icons.play_arrow),
        iconSize: 50,
        onPressed: () async {
          if (playing)
            await AudioService.pause();
          else
            await AudioService.play();
        },
      );

  Widget positionScrubber(MediaItem mediaItem, PlaybackState state) {
    double seekPos;
    return StreamBuilder(
      stream: Rx.combineLatest2(_dragPositionSubject.stream,
          Stream.periodic(Duration(milliseconds: 200)), (a, _) => a),
      builder: (context, snapshot) {
        final position =
            snapshot.data ?? state.currentPosition.inMilliseconds.toDouble();
        final duration = mediaItem?.duration?.inMilliseconds?.toDouble();

        return Column(
          children: <Widget>[
            if (duration != null) ...[
              SliderTheme(
                data: SliderThemeData(
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                  thumbColor: Theme.of(context).primaryColor,
                  trackHeight: 2,
                ),
                child: Slider(
                  min: 0,
                  max: duration,
                  value: seekPos ?? max(0, min(position, duration)),
                  inactiveColor: Colors.white24,
                  activeColor: Colors.white,
                  onChanged: (value) {
                    _dragPositionSubject.add(value);
                  },
                  onChangeEnd: (value) {
                    AudioService.seekTo(Duration(milliseconds: value.toInt()));
                    seekPos = value;
                    _dragPositionSubject.add(null);
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_buildTimestamp(state.currentPosition)),
                    Text(_buildTimestamp(mediaItem.duration)),
                  ],
                ),
              ),
              // Text('${state.currentPosition}'),
            ],
          ],
        );
      },
    );
  }

  String _buildTimestamp(Duration d) =>
      '${d.inMinutes.floor()}:${(d.inSeconds % 60).floor().toString().padLeft(2, '0')}';
}
