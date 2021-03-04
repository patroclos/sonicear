import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

import 'sqflite_album_dao.dart';
import 'sqflite_song_dao.dart';

class DbArtist {
  final String id;
  final String serverId;
  final String name;
  final String coverId;

  DbArtist({
    @required this.id,
    @required this.serverId,
    @required this.name,
    @required this.coverId,
  });

  factory DbArtist.fromRow(Map<String, dynamic> row) =>
      DbArtist(
          id: row['id'],
          serverId: row['serverId'],
          name: row['name'],
          coverId: row['coverId']
      );

  Map<String, dynamic> get asMap =>
      {
        'id': id,
        'serverId': serverId,
        'name': name,
        'coverId': coverId
      };

  @override
  String toString() {
    return 'DbArtist{id: $id, serverId: $serverId, name: $name, coverId: $coverId}';
  }
}

class SqfliteArtistDao {
  static const String TABLE_NAME = 'artists';

  final Database _db;

  SqfliteArtistDao(Database db) : _db = db;

  Future<List<DbArtist>> listAlbums({int count, int skip = 0}) async {
    final rows = await _db.query(TABLE_NAME, limit: count, offset: skip);

    return rows.map((row) => DbArtist.fromRow(row)).toList();
  }
}
