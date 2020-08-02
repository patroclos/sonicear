import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/db/repository.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/requests/search3.dart';
import 'extensions.dart';

class SearchMusic {
  final SubsonicContext _subsonic;
  final Repository _repo;

  SearchMusic._(this._subsonic, this._repo);

  factory SearchMusic.of(BuildContext context) {
    return SearchMusic._(context.watch(), context.watch());
  }

  Future<Iterable<DbSong>> call(String query) async {
    final results = (await Search3(query).run(_subsonic)).data;

    final dbSongs = results.songs.map((song) => song.toDbSong()).toList();

    final sw = Stopwatch()..start();
    await _repo.songs.ensureSongsExist(dbSongs);
    sw.stop();
    print('EnsureSongs ${sw.elapsed}');
    // await Future.wait(dbSongs.map((song) =>_repo.songs.ensureSongsExist(song)));

    // TODO: also handle non-song search results in the future
    return dbSongs;
  }
}