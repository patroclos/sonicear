import 'package:meta/meta.dart';
import 'token.dart';

class SubsonicContext {
  final Uri endpoint;
  final String version = '1.15.0';
  final String user;
  final String _pass;

  SubsonicContext({
    @required this.endpoint,
    @required this.user,
    @required String pass,
  }) : _pass = pass;

  AuthToken get token => AuthToken(_pass);

  Uri buildRequestUri(String name, {Map<String, String> params}) {
    var uri = endpoint.resolve("rest/$name");
    uri = uri.replace(
        queryParameters: Map.from(uri.queryParameters)..addAll(params ?? {}));
    return applyParameters(uri);
  }

  Uri applyParameters(Uri uri) {
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
