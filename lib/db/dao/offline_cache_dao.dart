import 'dart:io';

import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class CachedSong {}

abstract class OfflineCacheDao {
  Future<void> songCachedAt({
    @required String songId,
    @required String serverId,
    @required File musicFile,
  });

  Future<void> removeTaskOf(String songId, String serverId);

  Future<void> trackTask({
    @required String songId,
    @required String serverId,
    @required String taskId,
  });
}

class SqfliteOfflineCacheDao implements OfflineCacheDao {
  static const String CACHED_SONGS = 'cached_songs';
  static const String DOWNLOAD_TASKS = 'song_download_tasks';

  final Database _db;

  SqfliteOfflineCacheDao(this._db);

  Future<void> songCachedAt({
    @required String songId,
    @required String serverId,
    @required File musicFile,
  }) async {
    await Future.wait([
      removeTaskOf(songId, serverId),
      _db.insert(CACHED_SONGS, {
        'id': Uuid().v4(),
        'songId': songId,
        'serverId': serverId,
        'bitrate': null,
        'songFile': musicFile.path,
      })
    ]);
  }

  Future<void> trackTask({
    @required String songId,
    @required String serverId,
    @required String taskId,
  }) async {
    await _db.insert(DOWNLOAD_TASKS, {'songId': songId, 'serverId': serverId, 'taskId': taskId});
  }

  Future<void> removeTaskOf(String songId, String serverId) async {
    await _db.delete(DOWNLOAD_TASKS,
        where: 'songId = ? AND serverId = ?', whereArgs: [songId, serverId]);
  }
}
