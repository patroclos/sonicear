// TODO: offset, etc
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/models/models.dart';
import 'package:sonicear/subsonic/requests/search3.dart';

class SearchMusic {
  final SubsonicContext _subsonic;


  SearchMusic._(this._subsonic);

  factory SearchMusic.of(BuildContext context) {
    return SearchMusic._(context.watch());
  }

  // TODO: specialize type
  Future<Iterable<Song>> call(String query) async {
    final results = (await Search3(query).run(_subsonic)).data;
    print({'rez': results});
    // TODO: ensure results exist in db and give back db models
    return results.songs;
  }
}