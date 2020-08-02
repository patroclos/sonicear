import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:sonicear/db/dao/sqflite_server_dao.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/models/models.dart';

/// core data-model for songs/playables in the context of the app
/// always db-related?
/// contains all information needed for playback
class SongMetadata {
  final String appSongId;
  final Song apiSong;

  // defer for now, until we implement the layer
  // final File cachedMusic;
  // final File cachedCoverArt;

  SongMetadata(
    this.appSongId,
    this.apiSong,
  );
}

class LiftSong {
  Future<SongMetadata> call(Song apiSong) async {
    return SongMetadata(
      ServerCompoundId(apiSong.serverId, apiSong.id).toString(),
      apiSong,
    );
  }
}
