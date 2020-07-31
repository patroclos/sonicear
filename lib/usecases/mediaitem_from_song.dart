import 'package:audio_service/audio_service.dart';
import 'package:sonicear/audio/playback_utils.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/models/models.dart';
import 'package:sonicear/subsonic/requests/get_cover_art.dart';

abstract class MediaItemFromSong {
  MediaItem call(Song song);
}
// TODO: get some cross-server unique ids
class OnlineMediaItemFromSong implements MediaItemFromSong {
  final SubsonicContext _context;

  OnlineMediaItemFromSong(SubsonicContext context) : _context = context;

  MediaItem call(Song song) => MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          album: song.album,
          duration: song.duration,
          artUri: GetCoverArt(song.coverArt, size: 300).getImageUrl(_context),
          extras: {
            kStreamUrl: _context
                .buildRequestUri('stream', params: {'id': song.id}).toString(),
            kCoverId: song.coverArt
          });
}
