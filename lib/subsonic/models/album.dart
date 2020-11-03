import 'package:meta/meta.dart';

class Album {
  final String id;
  final String parent;
  final String title;
  final String artist;
  final bool isDir;
  final String coverArt;

  Album({
    @required this.id,
    this.parent,
    @required this.title,
    @required this.artist,
    this.isDir,
    this.coverArt,
  });

  factory Album.parse(Map<String, dynamic> data) {
    return Album(
      id: data['id'],
      parent: data['parent'],
      title: data['title'],
      artist: data['artist'],
      isDir: data['isDir'],
      coverArt: data['coverArt'],
    );
  }
}

class Album2 {
  final String id;
  final String serverId;
  final String name;

  final String coverArt;
  final int songCount;
  final DateTime created;
  final Duration duration;

  final String artist;
  final String artistId;

  Album2({
    @required this.id,
    @required this.serverId,
    @required this.name,
    @required this.coverArt,
    @required this.songCount,
    @required this.created,
    @required this.duration,
    @required this.artist,
    @required this.artistId,
  });

  factory Album2.parse(Map<String, dynamic> data, {@required String serverId}) {
    return Album2(
      id: data['id'].toString(),
      serverId: serverId,
      name: data['name'],
      coverArt: data['coverArt'],
      songCount: data['songCount'],
      created: DateTime.parse(data['created']),
      duration: Duration(seconds: data['duration']),
      artist: data['artist'],
      artistId: data['artistId'],
    );
  }

  @override
  String toString() {
    return 'Album2{id: $id, serverId: $serverId, name: $name}';
  }
}
