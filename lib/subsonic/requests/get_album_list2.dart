import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

import '../context.dart';
import '../count_offset.dart';
import '../response.dart';
import '../base_request.dart';
import '../models/album.dart';

enum AlbumList2Type {
  random,
  newest,
  frequent,
  recent,
  starred,
  alphabeticalByName,
  alphabeticalByArtist,
  byYear,
  byGenre
}

extension AlbumList2TypeToString on AlbumList2Type {
  String get name {
    switch (this) {
      case AlbumList2Type.random:
        return 'random';
      case AlbumList2Type.newest:
        return 'newest';
      case AlbumList2Type.frequent:
        return 'frequent';
      case AlbumList2Type.recent:
        return 'recent';
      case AlbumList2Type.starred:
        return 'starred';
      case AlbumList2Type.alphabeticalByName:
        return 'alphabeticalByName';
      case AlbumList2Type.alphabeticalByArtist:
        return 'alphabeticalByArtist';
      case AlbumList2Type.byYear:
        return 'byYear';
      case AlbumList2Type.byGenre:
        return 'byGenre';
      default:
        throw StateError('unhandled AlbumList2Type $this');
    }
  }
}

class GetAlbumList2 extends BaseRequest<List<Album2>> {
  final AlbumList2Type type;
  final CountOffset slice;
  final int fromYear;
  final int toYear;
  final String genre;
  final String musicFolderId;

  @override
  String get sinceVersion => '1.8.0';

  GetAlbumList2({
    @required this.type,
    this.slice = const CountOffset(count: 10, offset: 0),
    this.fromYear,
    this.toYear,
    this.genre,
    this.musicFolderId,
  });

  @override
  Future<SubsonicResponse<List<Album2>>> run(SubsonicContext ctx) async {
    final uri = ctx.buildRequestUri('getAlbumList2', params: {
      'type': this.type.name,
      if (slice.count != 10) 'count': '${slice.count}',
      if (slice.offset != 0) 'offset': '${slice.offset}',
      if (fromYear != null) 'fromYear': '$fromYear',
      if (toYear != null) 'toYear': '$toYear',
      if (genre != null) 'genre': genre,
      if (musicFolderId != null) 'musicFolderId': musicFolderId
    });

    final response = await http.get(uri);
    final data = jsonDecode(response.body)['subsonic-response'];

    if (data['status'] != 'ok')
      throw Exception('$runtimeType request failed: $data');

    final albums = (data['albumList2']['album'] as List ?? const [])
        .map((album) => Album2.parse(album, serverId: ctx.serverId))
        .toList();

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      albums,
    );
  }
}
