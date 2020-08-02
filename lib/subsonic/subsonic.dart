import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sonicear/subsonic/base_request.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/response.dart';

export 'token.dart';
export 'response.dart';
export 'base_request.dart';
export 'context.dart';
export 'models/models.dart';

enum SubsonicResponseFormat { xml, json, jsonp }

extension FormatToString on SubsonicResponseFormat {
  String serialize() {
    return this == SubsonicResponseFormat.xml
        ? 'xml'
        : this == SubsonicResponseFormat.json ? 'json' : 'jsonp';
  }
}

class GetArtistsData {
  final String ignoredArticles;
  final List<ArtistIndexEntry> index;

  GetArtistsData(this.ignoredArticles, List<ArtistIndexEntry> index)
      : this.index = List.unmodifiable(index);

  @override
  String toString() {
    return 'GetArtistsData{ignoredArticles: $ignoredArticles, index: $index}';
  }
}

class ArtistIndexEntry {
  final String name;
  final List<Artist> artist;

  ArtistIndexEntry(this.name, List<Artist> artist)
      : this.artist = List.unmodifiable(artist);

  @override
  String toString() {
    return 'ArtistIndexEntry{name: $name, artist: $artist}';
  }
}

class Artist {
  final String id;
  final String name;
  final String coverArt;
  final int albumCount;

  Artist(this.id, this.name, this.coverArt, this.albumCount);

  @override
  String toString() {
    return 'Artist{id: $id, name: $name, coverArt: $coverArt, albumCount: $albumCount}';
  }
}

class GetArtistsRequest extends BaseRequest<GetArtistsData> {
  final String musicFolderId;

  GetArtistsRequest({this.musicFolderId});

  @override
  String get sinceVersion => "1.8.0";

  @override
  Future<SubsonicResponse<GetArtistsData>> run(SubsonicContext ctx) async {
    var uri = ctx.endpoint.resolve("rest/getArtists");
    uri = ctx.applyUriParams(uri);
    if (musicFolderId != null)
      uri = uri.replace(queryParameters: Map.from(uri.queryParameters)..['musicFolderId'] = '$musicFolderId');

    final response = await http.get(uri);

    final data = jsonDecode(response.body);

    final status = data['subsonic-response']['status'];
    if (status == 'failed') {
      throw StateError('${data['subsonic-response']['error']['code']}');
    }

    final artists = data['subsonic-response']['artists'];

    final out = GetArtistsData(
      artists['ignoredArticles'],
      (artists['index'] as List).map((entry) {
        return ArtistIndexEntry(
          entry['name'],
          (entry['artist'] as List).map((artist) {
            return Artist(
              artist['id'],
              artist['name'],
              artist['coverArt'],
              artist['albumCount'],
            );
          }).toList(),
        );
      }).toList(),
    );


    return SubsonicResponse(ResponseStatus.ok, data['version'], out);
  }
}

