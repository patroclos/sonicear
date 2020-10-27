import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:sonicear/audio/playback_utils.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/provider/offline_cache.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/requests/get_cover_art.dart';

abstract class MediaItemFromSong {
  FutureOr<MediaItem> call(DbSong song);
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

// TODO: resolve to an item w/ a file:// extra kStreamUrl
class CachedOrOnlineMediaItemFromSong implements MediaItemFromSong {
  final OfflineCache cache;
  final SubsonicContext context;

  CachedOrOnlineMediaItemFromSong(this.cache, this.context);

  FutureOr<MediaItem> call(DbSong song) async {
    final cached = await cache.getCachedSong(song);

    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration: song.duration,
      artUri: GetCoverArt(song.coverId, size: 300).getImageUrl(context), // TODO: cached cover? how to cache cover url w/ auth inside url??
      extras: {
        ...song.asMap.map((k,v)=>MapEntry('$kInternalSong:$k', v)),
        kStreamUrl: cached != null
          ? Uri(scheme: 'file', path: cached.songFile.path).toString()
          : context.buildRequestUri('stream', params: {'id': song.id}).toString(),
        kCoverId: song.coverId
      }
    );
  }
}
