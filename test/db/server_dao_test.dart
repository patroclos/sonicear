import 'package:flutter_test/flutter_test.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/models/models.dart';
import 'package:sonicear/usecases/extensions.dart';
import 'package:uuid/uuid.dart';

import 'db.dart';

void main() async {
  test('db roundtrip server is equal to initial object', () async {
    final dao = (await openTestRepository()).servers;
    final server = SubsonicContext(
        name: 'Test Server',
        endpoint: Uri.parse('http://192.168.2.106:8080/airsonic/rest/'),
        user: 'sonicear',
        pass: 'app',
        serverId: Uuid().v4()
    );
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
        duration: Duration(seconds: 88)
    );
    expect(()=>dao.ensureSongsExist([song.toDbSong()]), throwsException);
  });
}