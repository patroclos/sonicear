import 'package:http/http.dart' as http;

import '../subsonic.dart';

class Ping extends BaseRequest<void> {
  @override
  String get sinceVersion => "1.0.0";

  @override
  Future<SubsonicResponse<void>> run(SubsonicContext ctx) async {
    final response = await http.get(ctx.buildRequestUri('ping'));
    if(response.statusCode != 200)
      return Future.error('Ping received status ${response.statusCode}');
    return SubsonicResponse(ResponseStatus.ok, ctx.version, null);
  }
}