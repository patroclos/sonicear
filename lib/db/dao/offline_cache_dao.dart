import 'dart:io';

import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class CachedSong {
  final String songId;
  final String serverId;
  final File songFile;

  // TODO: add thumbnails to cache? cache somewhere else
  // final File thumbFile;

  CachedSong(this.songId, this.serverId, this.songFile);
}

abstract class OfflineCacheDao {
  Future<void> associateFile({
    @required String songId,
    @required String serverId,
    @required File musicFile,
  });

  Future<List<CachedSong>> list({
    int count = 10,
    int offset = 0,
  });

  Future<CachedSong> find(String songId, String serverId);

  Future<void> evictFile(File file);

  Future<void> removeDownloadTaskOf(String songId, String serverId);

  Future<void> associateDownloadTask({
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

  Future<void> associateFile({
    @required String songId,
    @required String serverId,
    @required File musicFile,
  }) async {
    await Future.wait([
      removeDownloadTaskOf(songId, serverId),
      _db.insert(CACHED_SONGS, {
        'id': Uuid().v4(),
        'songId': songId,
        'serverId': serverId,
        'bitrate': null,
        'songFile': musicFile.path,
      })
    ]);
  }

  Future<List<CachedSong>> list({
    int count = 10,
    int offset = 0,
  }) async {
    final rows = await _db.query(
      CACHED_SONGS,
      limit: count,
      offset: offset,
    );

    return rows.map(_parseCachedSong).toList();
  }

  Future<CachedSong> find(String songId, String serverId) async {
    final rows = await _db.query(
      CACHED_SONGS,
      where: 'songId = ? AND serverId = ?',
      whereArgs: [songId, serverId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    return _parseCachedSong(rows.first);
  }

  CachedSong _parseCachedSong(Map<String, dynamic> row) => CachedSong(
        row['songId'],
        row['serverId'],
        File(row['songFile']),
      );

  Future<void> evictFile(File file) async {
    await _db
        .delete(CACHED_SONGS, where: 'songFile = ?', whereArgs: [file.path]);
  }

  Future<void> associateDownloadTask({
    @required String songId,
    @required String serverId,
    @required String taskId,
  }) async {
    await _db.insert(DOWNLOAD_TASKS,
        {'songId': songId, 'serverId': serverId, 'taskId': taskId});
  }

  Future<void> removeDownloadTaskOf(String songId, String serverId) async {
    await _db.delete(DOWNLOAD_TASKS,
        where: 'songId = ? AND serverId = ?', whereArgs: [songId, serverId]);
  }
}
