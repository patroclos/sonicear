import 'package:meta/meta.dart';
import 'package:sonicear/db/dao/offline_cache_dao.dart';
import 'package:sonicear/db/dao/sqflite_server_dao.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sqflite/sqflite.dart';

class Repository {
  final SqfliteSongDao songs;
  final SqfliteServerDao servers;
  final OfflineCacheDao offlineCache;

  Repository({
    @required this.songs,
    @required this.servers,
    @required this.offlineCache,
  });
}

Repository createSqfliteRepository(Database db) {
  return Repository(
    songs: SqfliteSongDao(db),
    servers: SqfliteServerDao(db),
    offlineCache: SqfliteOfflineCacheDao(db),
  );
}
