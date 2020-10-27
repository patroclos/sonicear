import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:path/path.dart' as path;

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:sonicear/db/dao/offline_cache_dao.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/usecases/song_cache_file_location.dart';

// TODO: move to db

class OfflineCache with ChangeNotifier {
  static const _portName = 'offlinecache_downloader_send_port';

  final ReceivePort _port = ReceivePort();
  StreamSubscription _sub;

  final _songTasks = <String, DbSong>{};

  OfflineCacheDao _dao;

  OfflineCache() {
    _sub = _port.listen(_handleMessage);

    IsolateNameServer.registerPortWithName(_port.sendPort, _portName);
    FlutterDownloader.registerCallback(_downloadCallback);
  }

  void setDao(OfflineCacheDao dao) {
    _dao = dao;

    // TODO: seeed _songTasks w/ db entries x-ref w/ actual tasks
  }

  bool hasCachingTask(DbSong song) {
    return _songTasks.values
        .any((s) => s.serverId == song.serverId && s.id == song.id);
  }

  Future<CachedSong> getCachedSong(DbSong song) {
    return _dao.findCached(song.id, song.serverId);
  }

  Future makeAvailableOffline(DbSong song, SubsonicContext context) async {
    final uri =
        context.buildRequestUri('download', params: {'id': song.id}).toString();

    final fileName = await SongCacheFileLocation()(song);
    await fileName.parent.create(recursive: true);

    final taskId = await FlutterDownloader.enqueue(
      url: uri,
      savedDir: fileName.parent.path,
      fileName: path.basename(fileName.path),
      showNotification: false,
    );

    await _registerTask(taskId, song);
  }

  Future evict(DbSong song) async {
    final cached = await _dao.findCached(song.id, song.serverId);
    if(cached == null)
      return;

    await cached.songFile.delete();
    await _dao.evicted(cached.songFile);
  }

  Future<void> _registerTask(String taskId, DbSong song) async {
    _songTasks[taskId] = song;
    await _dao.trackTask(
      songId: song.id,
      serverId: song.serverId,
      taskId: taskId,
    );

    notifyListeners();
  }

  void _handleMessage(dynamic message) async {
    final String taskId = message[0];
    final DownloadTaskStatus status = message[1];
    final int progress = message[2];

    if (!_songTasks.containsKey(taskId)) return;

    final song = _songTasks[taskId];
    print('Song Progress \'${song.title}\': $progress $status');

    if (status == DownloadTaskStatus.canceled ||
        status == DownloadTaskStatus.failed) {
      await _dao.removeTaskOf(song.id, song.serverId);
      print('song ${song.title} failed downloading');
      _songTasks.remove(taskId);
    }

    if (status == DownloadTaskStatus.complete) {
      print('song ${song.title} completely downloaded');

      final loc = await SongCacheFileLocation()(song);
      _dao.songCachedAt(
        songId: song.id,
        serverId: song.serverId,
        musicFile: loc,
      );
      _songTasks.remove(taskId);
    }

    notifyListeners();
    // print('Downloader RCV: tId=$taskId, status=$status, p=$progress');
  }

  void dispose() {
    super.dispose();
    _port.close();
    _sub.cancel();
    IsolateNameServer.removePortNameMapping(_portName);
  }

  static void _downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort send = IsolateNameServer.lookupPortByName(_portName);
    send.send([id, status, progress]);
  }
}
