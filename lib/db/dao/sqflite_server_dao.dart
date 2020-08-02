import 'package:meta/meta.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class ServerCompoundId {
  final String serverId;
  final String specialization;

  ServerCompoundId(this.serverId, this.specialization);

  factory ServerCompoundId.parse(String compound) {
    final i = compound.indexOf(';');

    return ServerCompoundId(
        compound.substring(0, i), compound.substring(i + 1));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerCompoundId &&
          runtimeType == other.runtimeType &&
          serverId == other.serverId &&
          specialization == other.specialization;

  @override
  int get hashCode => serverId.hashCode ^ specialization.hashCode;

  @override
  String toString() => '$serverId;$specialization';
}

class ServerInfo {
  final String id;
  final String name;
  final Uri uri;
  final String user;
  final String pass;

  ServerInfo({
    String id,
    @required this.name,
    @required this.uri,
    @required this.user,
    @required this.pass,
  }) : this.id = id ?? Uuid().v4();

  factory ServerInfo.parse(Map<String, dynamic> data) => ServerInfo(
        id: data['id'],
        name: data['name'],
        uri: data['uri'].runtimeType == Uri ? data['uri'] : Uri.parse(data['uri']),
        user: data['user'],
        pass: data['pass'],
      );

  ServerCompoundId makeCompoundId(String specialization) =>
      ServerCompoundId(id, specialization);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServerInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          uri == other.uri &&
          user == other.user &&
          pass == other.pass;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      uri.hashCode ^
      user.hashCode ^
      pass.hashCode;
}

class SqfliteServerDao {
  static const String TABLE_NAME = 'subsonic_servers';

  final Database _db;

  SqfliteServerDao(Database database) : _db = database;

  Future<List<SubsonicContext>> listServers() async {
    final rows = await _db.query(TABLE_NAME);
    return rows.map((row) => SubsonicContext.parse(row)).toList();
  }

  Future<SubsonicContext> ensureServerExists(SubsonicContext info) async {
    await _db.insert(TABLE_NAME, info.serialized, conflictAlgorithm: ConflictAlgorithm.replace);
    return info;
  }

  Future<SubsonicContext> getServer(String id) async {
    final rows = await _db.query(TABLE_NAME, where: 'id = ?', whereArgs: [id]);
    final row = rows[0];

    return SubsonicContext.parse(row);
  }
}
