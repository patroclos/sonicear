import 'package:audio_service/audio_service.dart';
import 'package:meta/meta.dart';
import 'package:sonicear/audio/audio.dart';
import 'package:sonicear/db/dao/sqflite_server_dao.dart';
import 'package:sonicear/subsonic/models/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class DbOfflineSong {
  final String songId;
  final String fileLocation;
  final String coverLocation;

  DbOfflineSong({
    @required this.songId,
    @required this.fileLocation,
    @required this.coverLocation,
  })  : assert(songId != null),
        assert(fileLocation != null),
        assert(coverLocation != null);

  factory DbOfflineSong.fromRaw(Map<String, dynamic> data) {
    return DbOfflineSong(
      songId: data['songId'],
      fileLocation: data['fileLocation'],
      coverLocation: data['coverLocation'],
    );
  }
}

class DbSong {
  final String id;
  final String title;
  final String artist;
  final String album;
  final int duration;
  final int track;
  final String coverId;

  DbSong({
    this.id,
    @required this.title,
    this.artist,
    this.album,
    @required this.duration,
    this.track,
    this.coverId,
  });

  factory DbSong.fromRow(Map<String, dynamic> row) {
    return DbSong(
      id: row['id'],
      title: row['title'],
      artist: row['artist'],
      album: row['album'],
      duration: row['duration'],
      track: row['track'],
      coverId: row['coverId'],
    );
  }

  @override
  String toString() {
    return 'DbSong{id: $id, title: $title, artist: $artist, album: $album, duration: $duration, track: $track, coverId: $coverId}';
  }
}

class SqfliteSongDao {
  static const String TABLE_NAME = 'songs';

  final Database _db;

  SqfliteSongDao(Database db) : _db = db;

  Future<Song> storeSong(Song song) async {
    final data = {
      'id': song.id,
      'serverId': song.serverId,
      'title': song.title,
      'duration': song.duration.inSeconds,
      'artist': song.artist,
      'album': song.album,
      'track': song.track,
      'coverId': song.coverArt,
          //'https://images.shazam.com/coverart/t405795898-b1477625824_s400.jpg'
    };

    await _db.insert(TABLE_NAME, data);

    return song;
  }

  Future<Song> loadSong(ServerCompoundId key) async {
    final row = await _db.query(TABLE_NAME, where: 'id = ? and serverId = ?', whereArgs: [key.specialization, key.serverId]);

    return Song.parse(row[0], serverId: row[0]['serverId']);
  }

  Future<DbOfflineSong> downloadSong(PlayableSong playable) async {
    // playable.
  }

  Future<DbSong> load(String id) async {
    final rows =
        await _db.query(TABLE_NAME, where: '"id" = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return DbSong.fromRow(rows.first);
  }
// Future<Object>
}
