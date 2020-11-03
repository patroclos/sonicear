import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/db/repository.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/count_offset.dart';
import 'package:sonicear/subsonic/requests/search3.dart';
import 'extensions.dart';

class SearchMusic {
  final SubsonicContext _subsonic;
  final Repository _repo;

  SearchMusic(this._subsonic, this._repo);

  factory SearchMusic.of(BuildContext context) {
    return SearchMusic(context.watch(), context.watch());
  }

  Future<Iterable<DbSong>> call(
    String query, {
    CountOffset artist,
    CountOffset album,
    CountOffset song,
    String musicFolderId,
  }) async {
    final results = (await Search3(
      query,
      artist: artist,
      album: album,
      song: song,
      musicFolderId: musicFolderId,
    ).run(_subsonic))
        .data;

    final dbSongs = results.songs.map((song) => song.toDbSong()).toList();

    await _repo.songs.ensureSongsExist(dbSongs);

    // TODO: also handle non-song search results in the future
    return dbSongs;
  }
}
