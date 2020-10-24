import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sonicear/audio/music_background_task.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/db/offline_cache.dart';
import 'package:sonicear/subsonic/subsonic.dart';
import 'package:sonicear/usecases/mediaitem_from_song.dart';
import 'package:path/path.dart' as path;
import 'package:sonicear/usecases/song_cache_file_location.dart';

const String kCoverId = 'cover-id';
const String kInternalSong = 'internal-song';
const String kStreamUrl = 'stream-url';

Future<bool> playSong(DbSong song, MediaItemFromSong song2media) async {
  if (!AudioService.running && !await startSonicearAudioTask()) return false;

  await AudioService.playMediaItem(song2media(song));
  return true;
}


Future downloadSong(DbSong song, SubsonicContext subsonic) async {
  final uri = subsonic.buildRequestUri('download', params: {'id': song.id}).toString();

  /*
  final musicFolders = await getExternalStorageDirectories(type: StorageDirectory.music);

  final fileName = path.join(musicFolders[0].path, '${song.artist}', '${song.album}', '${song.track} - ${song.title}.${song.suffix}');
   */
  final fileName = await SongCacheFileLocation()(song);
  fileName.parent.createSync(recursive: true);
  final taskId = await FlutterDownloader.enqueue(
    url: uri,
    savedDir: fileName.parent.path,
    showNotification: true,
    openFileFromNotification: true,
    fileName: path.basename(fileName.path)
  );

  await OfflineCache.instance.registerTask(taskId, song);

  // TODO: write to the database, and keep track of the status, writing to the db when download completes

 // final _port = ReceivePort();
  // IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
  /*
  _port.listen((data){
    String id = data[0];
    DownloadTaskStatus status = data[1];
    int progress = data[2];
  });

  FlutterDownloader.r
   */
}
