import 'package:audio_service/audio_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sonicear/widgets/app_playback_state.dart';
import 'package:sonicear/widgets/sonic_playback.dart';

class PlaybackLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppPlaybackState>(
        stream: AppPlaybackState.stateStream,
        builder: (context, snapshot) {
          final currentSong = snapshot.data?.currentSong;
          final playing = snapshot.data?.playbackState?.playing ?? false;
          final songProgress = ((snapshot.data?.playbackState?.currentPosition?.inMilliseconds ?? 0) / (currentSong?.duration?.inMilliseconds ?? 1));
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Stack(
                children: <Widget>[
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 3,
                    color: Colors.white24,
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * songProgress,
                    height: 2,
                    color: Colors.white,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  if (currentSong != null) ...[
                    IconButton(
                      icon: Icon(Icons.keyboard_arrow_up),
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SonicPlayback()));
                      },
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(currentSong.title, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis,),
                          Text(currentSong.artist),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(playing
                              ? Icons.pause_circle_outline
                              : Icons.play_circle_outline),
                          onPressed: () async {
                            if (AudioService.running) {
                              if (playing)
                                await AudioService.pause();
                              else
                                await AudioService.play();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next),
                          onPressed: () async {
                            await AudioService.skipToNext();
                          },
                        ),
                      ],
                    ),
                  ]
                ],
              ),
            ],
          );
        });
    // TODO: implement build
    throw UnimplementedError();
  }
}
