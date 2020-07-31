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
