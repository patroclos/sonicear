import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:path/path.dart' as path;

class SongCacheFileLocation {
  Future<File> call(DbSong song) async {
    final dir =
        await getExternalStorageDirectories(type: StorageDirectory.music);
    return File(
      path.join(
        dir[0].path,
        song.artist,
        song.album,
        '${song.track} - ${song.title}.${song.suffix}',
      ),
    );
  }
}
