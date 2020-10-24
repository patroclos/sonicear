import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:sonicear/db/dao/offline_cache_dao.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/usecases/song_cache_file_location.dart';

class SongRef {
  final String id, serverId;

  SongRef(this.id, this.serverId);
}

/*
enum CachingStage {
  None,
  Downloading,
  Cached,
  Error
}

class CachedSongState {
  final SongRef song;
  final CachingStage stage;

  CachedSongState(this.song, this.stage);
}
 */
class CachedSong {
  final String songId;
  final String serverId;
  final File songFile;
  final File thumbFile;

  CachedSong(this.songId, this.serverId, this.songFile, this.thumbFile);
}

class OfflineCache {
  static OfflineCache _instance;

  static OfflineCache get instance {
    return _instance;
  }

  static const _portName = 'offlinecache_downloader_send_port';

  final ReceivePort _port = ReceivePort();
  StreamSubscription _sub;

  final _songTasks = <String, DbSong>{};
  
  final OfflineCacheDao dao;

  OfflineCache._(this.dao) {
    _sub = _port.listen(_handleMessage);

    IsolateNameServer.registerPortWithName(_port.sendPort, _portName);
    FlutterDownloader.registerCallback(_downloadCallback);
  }

  Future registerTask(String taskId, DbSong song) {
    // TODO: persist association?
    _songTasks[taskId] = song;
    print(_songTasks);
  }

  void _handleMessage(dynamic message) async {
    final String taskId = message[0];
    final DownloadTaskStatus status = message[1];
    final int progress = message[2];

    if(!_songTasks.containsKey(taskId))
      return;

    final song = _songTasks[taskId];
    print('Song Progress \'${song.title}\': $progress $status');

    if(status == DownloadTaskStatus.canceled || status == DownloadTaskStatus.failed) {
      print('song ${song.title} failed downloading');
    }

    if(status == DownloadTaskStatus.complete) {
      print('song ${song.title} completely downloaded');

      // TODO: find the file location
      final loc = await SongCacheFileLocation()(song);
      dao.songCachedAt(songId: song.id, serverId: song.serverId, musicFile: loc);
    }
    // print('Downloader RCV: tId=$taskId, status=$status, p=$progress');
  }

  // Stream<CachedSongState> observeSong(DbSong song) {}

  void dispose() {
    _port.close();
    _sub.cancel();
    IsolateNameServer.removePortNameMapping(_portName);
    if (_instance == this) _instance = null;
  }

  static void init(OfflineCacheDao dao) {
    if (_instance == null) _instance = OfflineCache._(dao);
  }

  static void _downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName(_portName);
    send.send([id, status, progress]);
  }
}
