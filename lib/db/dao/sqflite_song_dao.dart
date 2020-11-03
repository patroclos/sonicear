import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';

class DbSong {
  final String id;
  final String serverId;
  final String title;
  final String artist;
  final String album;
  final String suffix;
  final Duration duration;
  final int track;
  final String coverId;

  DbSong({
    @required this.id,
    @required this.serverId,
    @required this.title,
    this.artist,
    this.album,
    @required this.duration,
    @required this.suffix,
    this.track,
    this.coverId,
  });

  factory DbSong.fromRow(Map<String, dynamic> row) {
    return DbSong(
      id: row['id'],
      serverId: row['serverId'],
      title: row['title'],
      artist: row['artist'],
      album: row['album'],
      duration: Duration(seconds: row['duration']),
      suffix: row['suffix'],
      track: row['track'],
      coverId: row['coverId'],
    );
  }

  Map<String, dynamic> get asMap => {
        'id': id,
        'serverId': serverId,
        'title': title,
        'artist': artist,
        'album': album,
        'duration': duration.inSeconds,
        'suffix': suffix,
        'track': track,
        'coverId': coverId,
      };

  @override
  String toString() {
    return 'DbSong{id: $id, serverId: $serverId, title: $title, artist: $artist, album: $album, duration: $duration, track: $track, coverId: $coverId}';
  }
}

class SqfliteSongDao {
  static const String TABLE_NAME = 'songs';

  final Database _db;

  SqfliteSongDao(Database db) : _db = db;

  Future<void> ensureSongsExist(List<DbSong> songs) async {
    final data = songs.map((song) => song.asMap);

    final batch = _db.batch();
    for (final song in data) {
      batch.rawInsert(
        '''INSERT INTO $TABLE_NAME (id, serverId, title, artist, album, duration, suffix, track, coverId)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(id, serverId) DO UPDATE SET
              title=excluded.title,
              artist=excluded.artist,
              album=excluded.album,
              duration=excluded.duration,
              suffix=excluded.suffix,
              track=excluded.track,
              coverId=excluded.coverId''',
        [
          'id',
          'serverId',
          'title',
          'artist',
          'album',
          'duration',
          'suffix',
          'track',
          'coverId'
        ].map((k) => song[k])
        .toList(),
      );
    }

    await batch.commit(noResult: true);
  }

  Future<DbSong> loadSong({
    @required String serverId,
    @required String songId,
  }) async {
    final row = await _db.query(
      TABLE_NAME,
      where: 'id = ? and serverId = ?',
      whereArgs: [songId, serverId],
    );

    return DbSong.fromRow(row[0]);
  }

  Future<int> countSongs() {
    return _db
        .rawQuery('SELECT COUNT(1) as count FROM $TABLE_NAME')
        .then((data) => data[0]['count']);
  }

  Future<List<DbSong>> listSongs(int count, int skip) async {
    final rows = await _db.query(
      TABLE_NAME,
      limit: count,
      offset: skip,
    );

    return rows.map((row) => DbSong.fromRow(row)).toList();
  }
}
