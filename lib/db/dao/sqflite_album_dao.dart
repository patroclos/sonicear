import 'package:meta/meta.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sqflite/sqflite.dart';

class DbAlbum {
  final String id;
  final String serverId;

  final String title;
  final String artistId;
  final String coverArt;

  DbAlbum({
    @required this.id,
    @required this.serverId,
    @required this.title,
    this.artistId,
    @required this.coverArt,
  });

  factory DbAlbum.fromRow(Map<String, dynamic> row) {
    return DbAlbum(
        id: row['id'],
        serverId: row['serverId'],
        title: row['title'],
        artistId: row['artistId'],
        coverArt: row['coverArt']);
  }

  Map<String, dynamic> get asMap => {
        'id': id,
        'serverId': serverId,
        'title': title,
        'artistId': artistId,
        'coverArt': coverArt
      };

  @override
  String toString() {
    return 'DbAlbum{id: $id, serverId: $serverId, title: $title, artistId: $artistId, coverArt: $coverArt}';
  }
}

class SqfliteAlbumDao {
  static const String TABLE_NAME = 'albums';
  static const String SONG_ASSOC_TABLE_NAME = 'album_songs';

  final Database _db;
  final SqfliteSongDao songDao;

  SqfliteAlbumDao(Database db, this.songDao) : _db = db;

  // TODO: Insert/Ensure/Remove

  Future<List<DbSong>> getSongsOf(DbAlbum album) async {
    final songTable = SqfliteSongDao.TABLE_NAME;
    final data = await this._db.rawQuery(
        'SELECT `$songTable`.* FROM `$SONG_ASSOC_TABLE_NAME` JOIN `$songTable` ON $songTable.serverId = $SONG_ASSOC_TABLE_NAME.serverId AND $songTable.id = $SONG_ASSOC_TABLE_NAME.songId WHERE $SONG_ASSOC_TABLE_NAME.albumId = ? AND $SONG_ASSOC_TABLE_NAME.serverId = ?',
        [album.id, album.serverId]);
    return data.map((row) => DbSong.fromRow(row)).toList();
  }

  Future<List<DbAlbum>> listAlbums({int count, int skip = 0}) async {
    final rows = await _db.query(TABLE_NAME, limit: count, offset: skip);

    return rows.map((row) => DbAlbum.fromRow(row)).toList();
  }
}
