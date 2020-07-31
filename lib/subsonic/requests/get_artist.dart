import 'dart:convert';

import 'package:sonicear/subsonic/subsonic.dart';
import 'package:http/http.dart' as http;

class GetArtist extends BaseRequest {
  final String id;

  GetArtist(this.id);

  @override
  String get sinceVersion => '1.8.0';

  @override
  Future<SubsonicResponse> run(SubsonicContext ctx) async {
    // TODO: parse response into artist name,cover,albumCount and list of album surface infos
    // TODO: implement getAlbum to get a list of songs of the albums
    final response =
        await http.get(ctx.buildRequestUri('getArtist', params: {'id': id}));
    final data = jsonDecode(response.body);
    if (data['subsonic-response']['status'] != 'ok') throw StateError(data);

    final artistData = data['subsonic-response']['artist'];
    final artist = {
      'id': artistData['id'],
      'name': artistData['name'],
      'coverArt': artistData['coverArt'],
      'albumCount': artistData['albumCount'],
      'albums': (artistData['album'] as List)
          .map(
            (album) => {
              'id': album['id'],
              'name': album['name'],
              'coverArt': album['coverArt'],
              'songCount': album['songCount'],
              'created': DateTime.parse(album['created']),
              'duration': Duration(seconds: int.parse(album['duration'])),
              'artist': album['artist'],
              'artistId': album['artistId'],
            },
          )
          .toList()
    };

    return artistData;
  }
}
