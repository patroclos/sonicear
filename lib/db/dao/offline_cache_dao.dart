import 'dart:io';

import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class CachedSong {}

abstract class OfflineCacheDao {
  // Future<List<CachedSong>> list({int count = 20, int skip = 0});
  // Future<void> evicted({String songId, String serverId});
  Future<void> songCachedAt({
    @required String songId,
    @required String serverId,
    @required File musicFile,
  });
}

class SqfliteOfflineCacheDao extends OfflineCacheDao {
  static const String TABLE_NAME = 'offline_songs';

  final Database _db;

  SqfliteOfflineCacheDao(this._db);

  Future<void> songCachedAt({
    @required String songId,
    @required String serverId,
    @required File musicFile,
  }) async {
    await _db.insert(TABLE_NAME, {
      'id': Uuid().v4(),
      'songId': songId,
      'serverId': serverId,
      'bitrate': null,
      'songFile': musicFile.path,
    });
  }
}
