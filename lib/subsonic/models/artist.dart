import 'package:meta/meta.dart';

class Artist {
  final String id;
  final String name;
  final String coverArt;
  final int albumCount;

  Artist({
    @required this.id,
    @required this.name,
    @required this.coverArt,
    this.albumCount,
  });

  factory Artist.parse(Map<String, dynamic> data) {
    return Artist(
      id: data['id'],
      name: data['name'],
      coverArt: data['coverArt'],
      albumCount: data['albumCount'],
    );
  }

  @override
  String toString() {
    return 'Artist{id: $id, name: $name, coverArt: $coverArt, albumCount: $albumCount}';
  }
}
