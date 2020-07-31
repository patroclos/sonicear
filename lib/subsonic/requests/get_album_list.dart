import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:sonicear/subsonic/subsonic.dart';
import 'package:http/http.dart' as http;

class GetAlbumList extends BaseRequest<List<Album>> {
  final String type;
  final int size;
  final int offset;
  final String musicFolderId;

  GetAlbumList({
    @required this.type,
    this.size,
    this.offset,
    this.musicFolderId,
  });

  @override
  String get sinceVersion => '1.2.0';

  @override
  Future<SubsonicResponse<List<Album>>> run(SubsonicContext ctx) async {
    final response = await http.get(ctx.buildRequestUri(
      'getAlbumList',
      params: {
        'type': type,
        'size': size.toString(),
        'offset': offset.toString(),
        'musicFolderId': musicFolderId
      }..removeWhere((key, value) => value == null),
    ));

    final data = jsonDecode(response.body)['subsonic-response'];
    print(data['albumList']['album'][0]);

    if (data['status'] != 'ok') throw StateError(data);

    return SubsonicResponse(
      ResponseStatus.ok,
      ctx.version,
      (data['albumList']['album'] as List)
          .map((album) => Album.parse(album))
          .toList(),
    );
  }
}
