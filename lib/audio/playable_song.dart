import 'dart:io';
import 'package:meta/meta.dart';

//

// this class is sendable
class PlayableSong {
  final String id;

  // TODO: split this into uri and file?
  final String coverImage;

  final Uri streamUri;
  final File localFile;

  final String title, album, artist;

  bool get isFile => localFile != null;
  bool get isStream => streamUri != null;

  PlayableSong.remote({
    @required this.id,
    @required this.title,
    this.album,
    this.artist,
    @required this.streamUri,
    this.coverImage,
  }): localFile = null;

  PlayableSong.downloaded({
    @required this.id,
    @required this.title,
    this.album,
    this.artist,
    @required this.localFile,
    this.coverImage,
  }): streamUri = null;
}
