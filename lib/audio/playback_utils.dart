import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sonicear/audio/music_background_task.dart';
import 'package:sonicear/subsonic/subsonic.dart';
import 'package:sonicear/usecases/mediaitem_from_song.dart';
import 'package:path/path.dart' as path;

const String kCoverId = 'cover-id';
const String kStreamUrl = 'stream-url';

Future<bool> playSong(Song song, MediaItemFromSong song2media) async {
  if (!AudioService.running && !await startSonicearAudioTask()) return false;

  await AudioService.playMediaItem(song2media(song));
  return true;
}


Future downloadSong(Song song, SubsonicContext subsonic) async {
  final uri = subsonic.buildRequestUri('download', params: {'id': song.id}).toString();

  final fileName = path.join((await getExternalStorageDirectory()).path, 'Music', '${song.artist}', '${song.album} ${song.track} - ${song.title}.${song.suffix}');
  Directory(path.dirname(fileName)).createSync(recursive: true);
  await FlutterDownloader.enqueue(
    url: uri,
    savedDir: path.dirname(fileName),
    showNotification: true,
    openFileFromNotification: true,
    fileName: path.basename(fileName)
  );

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
