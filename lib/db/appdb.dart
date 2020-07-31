import 'package:flutter/material.dart';
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
      // TODO: replace artist and album text w/ reference to tables
      await txn.execute('''
          CREATE TABLE songs (
            id CHARACTER(16) NOT NULL,
            serverId CHARACTER(36) NOT NULL,
            title TEXT NOT NULL,
            duration INT NOT NULL,
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

      await txn.execute('''
        CREATE TABLE offline_songs (
          songId CHARACTER(36) PRIMARY KEY REFERENCES songs(id) ON DELETE CASCADE,
          fileLocation TEXT NOT NULL,
          coverLocation TEXT NOT NULL
        )
      ''');
    }
  ];

  Future _openDatabase() async {
    final dbPath = await databasePath;
    final db = await openDatabase(
      dbPath,
      version: upgrades.length,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) => create(db, version: version),
      onUpgrade: (db, from, to) async {
        await Future.forEach<MapEntry<int, Future Function(Transaction)>>(
          upgrades.asMap().entries,
          (kv) {
            if (kv.key < to)
              return db.transaction(kv.value).then((_) => true);
            else
              return true;
          },
        );
      },
    );

    _dbOpenCompleter.complete(db);
  }
}
