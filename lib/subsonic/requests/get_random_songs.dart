import 'dart:convert';
import 'package:http/http.dart' as http;

import '../subsonic.dart';

class GetRandomSongs extends BaseRequest<List<Song>> {
  final int size;
  final String genre;
  final String fromYear;
  final String toYear;
  final String musicFolderId;

  GetRandomSongs({
    this.size,
    this.genre,
    this.fromYear,
    this.toYear,
    this.musicFolderId,
  });

  @override
  String get sinceVersion => "1.2.0";

  @override
  Future<SubsonicResponse<List<Song>>> run(SubsonicContext ctx) async {
    final response = await http.get(ctx.buildRequestUri(
      "getRandomSongs",
      params: {
        'size': '$size',
      },
    ));
    final data = jsonDecode(response.body)['subsonic-response'];

    if (data['status'] != 'ok') throw StateError(data);

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      (data['randomSongs']['song'] as List)
          .map(
            (song) => Song.parse(song, serverId: ctx.serverId),
          )
          .toList(),
    );
  }
}
