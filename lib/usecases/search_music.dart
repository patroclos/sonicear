import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/db/repository.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/models/models.dart';
import 'package:sonicear/subsonic/requests/search3.dart';

class SearchMusic {
  final SubsonicContext _subsonic;
  final Repository _repo;

  SearchMusic._(this._subsonic, this._repo);

  factory SearchMusic.of(BuildContext context) {
    return SearchMusic._(context.watch(), context.watch());
  }

  Future<Iterable<Song>> call(String query) async {
    final results = (await Search3(query).run(_subsonic)).data;
    print({'rez': results});
    await Future.wait(results.songs.map((song) =>_repo.songs.storeSong(song)));
    // TODO: ensure results exist in db and give back db models
    return results.songs;
  }
}