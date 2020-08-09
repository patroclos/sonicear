import 'package:sonicear/subsonic/context.dart';
import 'package:sqflite/sqflite.dart';

class SqfliteServerDao {
  static const String TABLE_NAME = 'subsonic_servers';

  final Database _db;

  SqfliteServerDao(Database database) : _db = database;

  Future<List<SubsonicContext>> listServers() async {
    final rows = await _db.query(TABLE_NAME);
    return rows.map((row) => SubsonicContext.parse(row)).toList();
  }

  Future<SubsonicContext> ensureServerExists(SubsonicContext info) async {
    await _db.insert(TABLE_NAME, info.serialized,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return info;
  }

  Future<bool> delete(SubsonicContext server) async {
    return (await _db.delete(TABLE_NAME,
            where: 'id = ?', whereArgs: [server.serverId])) >
        0;
  }

  Future<SubsonicContext> getActiveServer() async {
    final rows = await _db.query(TABLE_NAME, where: 'active = 1', limit: 1);
    if (rows.isEmpty) return null;
    return SubsonicContext.parse(rows[0]);
  }

  Future setActiveServer(SubsonicContext server) async {
    await _db.rawUpdate(
      'UPDATE $TABLE_NAME SET active = CASE id WHEN ? THEN 1 ELSE 0 END',
      [server.serverId],
    );
  }

  Future<SubsonicContext> getServer(String id) async {
    final rows = await _db.query(TABLE_NAME, where: 'id = ?', whereArgs: [id]);
    final row = rows[0];

    return SubsonicContext.parse(row);
  }
}
