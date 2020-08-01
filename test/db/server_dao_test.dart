import 'package:flutter_test/flutter_test.dart';
import 'package:sonicear/db/appdb.dart';
import 'package:sonicear/db/dao/sqflite_server_dao.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/subsonic/models/models.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  test('db roundtrip server is equal to initial object', () async {
    final db = await databaseFactoryFfi.openDatabase(':memory:');
    await AppDb.create(db);
    final dao = SqfliteServerDao(db);
    final server = ServerInfo(
      name: 'Test Server',
      uri: Uri.parse('http://192.168.2.106:8080/airsonic/rest/'),
      user: 'sonicear',
      pass: 'app',
    );
    await dao.createServer(server);

    final out = await dao.getServer(server.id);
    expect(out, equals(server));
  });

  test('song -> server fk is enforced', () async {
    final db = await databaseFactoryFfi.openDatabase(
      ':memory:',
      options: OpenDatabaseOptions(
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      ),
    );
    await AppDb.create(db);
    final dao = SqfliteSongDao(db);
    final song = Song(
        id: "1",
        serverId: "i dont exist dawg",
        title: 'Test Server',
        artist: 'sonicear',
        album: 'app',
        duration: Duration(seconds: 88)
        );
    expect(()=>dao.storeSong(song), throwsException);
  });
}
