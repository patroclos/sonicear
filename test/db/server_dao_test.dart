import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/models/models.dart';
import 'package:sonicear/usecases/extensions.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';

void main() async {
  sqfliteFfiInit();

  test('db roundtrip server is equal to initial object', () async {
    final dao = (await openTestRepository()).servers;
    final server = SubsonicContext(
        name: 'Test Server',
        endpoint: Uri.parse('http://192.168.2.106:8080/airsonic/rest/'),
        user: 'sonicear',
        pass: 'app',
        serverId: Uuid().v4());
    await dao.ensureServerExists(server);

    final out = await dao.getServer(server.serverId);
    expect(out, equals(server));
  });

  test('song -> server fk is enforced', () async {
    final dao = (await openTestRepository()).songs;
    final song = Song(
        id: "1",
        serverId: "i dont exist dawg",
        title: 'Test Server',
        artist: 'sonicear',
        album: 'app',
        duration: Duration(seconds: 88));
    expect(() => dao.ensureSongsExist([song.toDbSong()]), throwsException);
  });

  test('updating song doesn\'t corrupt offline_songs reference', () async {
    final repo = await openTestRepository();
    final server = SubsonicContext(
        name: 'Test Server',
        endpoint: Uri.parse('http://192.168.2.106:8080/airsonic/rest/'),
        user: 'sonicear',
        pass: 'app',
        serverId: Uuid().v4());
    await repo.servers.ensureServerExists(server);

    final song = DbSong(
      id: Uuid().v4(),
      serverId: server.serverId,
      title: 'My Cool Song',
      duration: Duration(seconds: 5),
      suffix: '.mp4',
    );

    await repo.songs.ensureSongsExist([song]);

    await repo.offlineCache.associateFile(songId: song.id, serverId: song.serverId, musicFile: File('i dont exist'));

    expect((await repo.offlineCache.list())[0].songId, isNotNull);

    final updatedSong = DbSong.fromRow(song.asMap..['title'] = 'My Cooler Song');
    await repo.songs.ensureSongsExist([updatedSong]);

    expect((await repo.offlineCache.list())[0].songId, isNotNull);
    expect((await repo.songs.listSongs(10, 0))[0].title, equals('My Cooler Song'));
  });
}
