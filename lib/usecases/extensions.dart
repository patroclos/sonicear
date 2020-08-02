import 'package:audio_service/audio_service.dart';
import 'package:sonicear/audio/audio.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/subsonic/models/models.dart';

extension ApiToDbSongConversionExtension on Song {
  DbSong toDbSong() => DbSong(
      id: this.id,
      serverId: this.serverId,
      title: this.title,
      duration: this.duration,
      suffix: this.suffix,
      artist: this.artist,
      album: this.album,
      coverId: this.coverArt,
      track: this.track);
}

extension DbSongFromMediaItem on MediaItem {
  DbSong extractDbSong() => DbSong.fromRow(
        Map.fromEntries(
          this
              .extras
              .entries
              .where(
                (kv) => kv.key.startsWith(kInternalSong),
              )
              .map(
                (kv) => MapEntry(
                  kv.key.substring(kInternalSong.length + 1),
                  kv.value,
                ),
              ),
        ),
      );
}
