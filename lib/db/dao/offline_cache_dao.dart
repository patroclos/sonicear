import 'dart:io';

import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class CachedSong {
  final String songId;
  final String serverId;
  final File songFile;

  // final File thumbFile;

  CachedSong(this.songId, this.serverId, this.songFile);
}

abstract class OfflineCacheDao {
  Future<void> songCachedAt({
    @required String songId,
    @required String serverId,
    @required File musicFile,
  });

  Future<CachedSong> findCached(String songId, String serverId);

  Future<void> evicted(File file);

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

  Future<CachedSong> findCached(String songId, String serverId) async {
    final rows = await _db.query(
      CACHED_SONGS,
      where: 'songId = ? AND serverId = ?',
      whereArgs: [songId, serverId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    return CachedSong(rows[0]['songId'], rows[0]['serverId'], File(rows[0]['songFile']));
  }

  Future<void> evicted(File file) async {
    await _db.delete(CACHED_SONGS, where: 'songFile = ?', whereArgs: [file.path]);
  }

  Future<void> trackTask({
    @required String songId,
    @required String serverId,
    @required String taskId,
  }) async {
    await _db.insert(DOWNLOAD_TASKS,
        {'songId': songId, 'serverId': serverId, 'taskId': taskId});
  }

  Future<void> removeTaskOf(String songId, String serverId) async {
    await _db.delete(DOWNLOAD_TASKS,
        where: 'songId = ? AND serverId = ?', whereArgs: [songId, serverId]);
  }
}
