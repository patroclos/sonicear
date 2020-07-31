import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';

class AppPlaybackState {
  final List<MediaItem> queue;
  final MediaItem currentSong;
  final PlaybackState playbackState;

  AppPlaybackState(this.queue, this.currentSong, this.playbackState);

  static Stream<AppPlaybackState> get stateStream => Rx.combineLatest4(
        AudioService.queueStream,
        AudioService.currentMediaItemStream,
        AudioService.playbackStateStream,
        Stream.periodic(Duration(milliseconds: 300)),
        (a, b, c, _) => AppPlaybackState(a, b, c),
      );
}
