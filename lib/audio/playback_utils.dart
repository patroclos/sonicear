import 'package:audio_service/audio_service.dart';
import 'package:sonicear/audio/music_background_task.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/usecases/mediaitem_from_song.dart';

const String kCoverId = 'cover-id';
const String kInternalSong = 'internal-song';
const String kStreamUrl = 'stream-url';

Future<bool> playSong(DbSong song, MediaItemFromSong song2media) async {
  if (!AudioService.running) {
    final success = await startSonicearAudioTask();
    if (!success) return false;
  }

  await AudioService.playMediaItem(await song2media(song));
  return true;
}
