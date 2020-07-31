import 'package:sonicear/db/appdb.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sqflite/sqflite.dart';

class Repository {
  final SqfliteSongDao songs;

  Repository({this.songs});
}

Repository createSqfliteRepository(Database db) {
  return Repository(songs: SqfliteSongDao(db));
}