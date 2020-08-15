import 'package:sonicear/db/appdb.dart';
import 'package:sonicear/db/repository.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Database> openTestDatabase() async {
  final db = await databaseFactoryFfi.openDatabase(
    ':memory:',
    options: OpenDatabaseOptions(
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, v) => AppDb.create(db, version: v),
        onUpgrade: (db, from, to) => AppDb.upgrade(db, from, to),
        version: AppDb.upgrades.length,
        singleInstance: false
    ),
  );

  return db;
}

Future<Repository> openTestRepository() async {
  final db = await openTestDatabase();
  return createSqfliteRepository(db);
}