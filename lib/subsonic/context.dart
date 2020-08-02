import 'package:meta/meta.dart';
import 'token.dart';

class SubsonicContext {
  final String serverId;
  final String name;
  final Uri endpoint;
  final String version = '1.15.0';
  final String user;
  final String _pass;

  SubsonicContext({
    @required this.serverId,
    @required this.name,
    @required this.endpoint,
    @required this.user,
    @required String pass,
  }) : _pass = pass, token = AuthToken(pass);

  factory SubsonicContext.parse(Map<String, dynamic> row) {
    return SubsonicContext(
      serverId: row['id'],
      name: row['name'],
      endpoint: Uri.parse(row['uri']),
      user: row['user'],
      pass: row['pass'],
    );
  }

  Map<String, dynamic> get serialized => {
        'id': serverId,
        'name': name,
        'uri': endpoint.toString(),
        'user': user,
        'pass': _pass,
      };

  // AuthToken get token => AuthToken(_pass);
  final AuthToken token;

  Uri buildRequestUri(String name, {Map<String, String> params}) {
    var uri = endpoint.resolve("rest/$name");
    uri = uri.replace(
        queryParameters: Map.from(uri.queryParameters)..addAll(params ?? {}));
    // print(uri);
    return applyUriParams(uri);
  }

  Uri applyUriParams(Uri uri) {
    final t = token;
    final params = {
      'v': version,
      'u': user,
      't': t.token,
      's': t.salt,
      'c': 'dartsonic',
      'f': 'json'
    };
    return uri.replace(
      queryParameters: Map.from(uri.queryParameters)..addAll(params),
    );
  }
}
