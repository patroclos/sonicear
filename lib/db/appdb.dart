import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'package:path/path.dart' as path;
import 'dart:async';

class AppDb {
  static final AppDb _singleton = AppDb._();

  static AppDb get instance => _singleton;

  Completer<Database> _dbOpenCompleter;

  AppDb._();

  Future<Database> get database async {
    if (_dbOpenCompleter == null) {
      _dbOpenCompleter = Completer();
      _openDatabase();
    }

    return _dbOpenCompleter.future;
  }

  Future<String> databasePath = (() async {
    //final p = path.join((await getApplicationDocumentsDirectory()).path, 'app.db');
    final p = path.join((await getExternalStorageDirectory()).path, 'app.db');
    return p;
  })();

  static Future create(Database db, {int version}) {
    return Future.forEach(
      upgrades.take(version ?? upgrades.length),
      (up) => db.transaction((txn) => up(txn)),
    );
  }

  static final upgrades = <Future Function(Transaction)>[
    (txn) async {
      await txn.execute('''
          CREATE TABLE subsonic_servers (
            id CHARACTER(36) PRIMARY KEY,
            name TEXT NOT NULL,
            uri TEXT NOT NULL,
            user TEXT NOT NULL,
            pass TEXT NOT NULL
          )
        ''');
    },
    (txn) async {
      await txn.execute('''
          CREATE TABLE songs (
            id CHARACTER(16) NOT NULL,
            serverId CHARACTER(36) NOT NULL,
            title TEXT NOT NULL,
            duration INT NOT NULL,
            suffix CHARACTER(8) NOT NULL,
            artist TEXT,
            album TEXT,
            track INT,
            coverId CHARACTER(16),
            
            PRIMARY KEY (id, serverId),
            CONSTRAINT fk_serverId
              FOREIGN KEY (serverId)
              REFERENCES subsonic_servers(id)
              ON DELETE CASCADE
          )
        ''');
    },
    (txn) async {
      await txn.execute('''
        ALTER TABLE subsonic_servers
        ADD active TINYINT NOT NULL CHECK (active IN (0,1)) DEFAULT 0
      ''');
    },
    (txn) async {
      await txn.execute('''
        CREATE TABLE cached_songs (
          id CHARACTER(36) PRIMARY KEY NOT NULL,
          songId CHARACTER(16),
          serverId CHARACTER(36),
          bitrate INT,
          songFile TEXT NOT NULL,
          
          CONSTRAINT fk_song
            FOREIGN KEY (songId, serverId)
            REFERENCES songs(id, serverId)
            ON DELETE SET NULL
        )
      ''');
    },
    (txn) async {
      await txn.execute('''
        CREATE TABLE song_download_tasks (
          taskId CHARACTER(36) PRIMARY KEY NOT NULL,
          songId CHARACTER(16),
          serverId CHARACTER(36),
          
          CONSTRAINT fk_song
            FOREIGN KEY (songId, serverId)
            REFERENCES songs(id, serverId)
            ON DELETE SET NULL,
          UNIQUE (songId, serverId)
        )
      ''');
    }
  ];

  static Future upgrade(Database db, int from, int to) async {
    await Future.forEach<MapEntry<int, Future Function(Transaction)>>(
      upgrades.asMap().entries,
      (kv) {
        if (kv.key >= from && kv.key < to)
          return db.transaction(kv.value).then((_) => true);
        else
          return true;
      },
    );
  }

  Future _openDatabase() async {
    final dbPath = await databasePath;
    final db = await openDatabase(
      dbPath,
      version: upgrades.length,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => create(db, version: version),
      onUpgrade: (db, from, to) => upgrade(db, from, to),
    );

    _dbOpenCompleter.complete(db);
  }
}
