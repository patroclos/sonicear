import 'package:audio_service/audio_service.dart';
import 'package:sonicear/audio/playback_utils.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/requests/get_cover_art.dart';

abstract class MediaItemFromSong {
  MediaItem call(DbSong song);
}

// TODO: get some cross-server unique ids
class OnlineMediaItemFromSong implements MediaItemFromSong {
  final SubsonicContext _context;

  OnlineMediaItemFromSong(SubsonicContext context) : _context = context;

  MediaItem call(DbSong song) => MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
        artUri: GetCoverArt(song.coverId, size: 300).getImageUrl(_context),
        extras: {
          ...song.asMap.map((k, v) => MapEntry('$kInternalSong:$k', v)),
          kStreamUrl: _context
              .buildRequestUri('stream', params: {'id': song.id}).toString(),
          kCoverId: song.coverId
        },
      );
}

