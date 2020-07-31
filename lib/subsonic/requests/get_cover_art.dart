import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../subsonic.dart';

class GetCoverArt extends BaseRequest<Uint8List> {
  final String id;
  final int size;

  GetCoverArt(this.id, {this.size});

  @override
  String get sinceVersion => '1.0.0';

  Uri _getImageUri(SubsonicContext ctx) {
    var uri = ctx.endpoint.resolve("rest/getCoverArt");
    uri = ctx.applyParameters(uri);
    uri = uri.replace(
        queryParameters: Map.from(uri.queryParameters)..['id'] = '$id');
    if (size != null)
      uri = uri.replace(
          queryParameters: Map.from(uri.queryParameters)..['size'] = '$size');

    return uri;
  }

  String getImageUrl(SubsonicContext ctx) => _getImageUri(ctx).toString();

  @override
  Future<SubsonicResponse<Uint8List>> run(SubsonicContext ctx) async {
    final uri = _getImageUri(ctx);

    final response = await http.get(uri);
    return SubsonicResponse(ResponseStatus.ok, ctx.version, response.bodyBytes);
  }
}
