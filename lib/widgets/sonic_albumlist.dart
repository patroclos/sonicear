import 'package:flutter/material.dart';
import 'package:sonicear/subsonic/subsonic.dart';
import 'package:sonicear/widgets/sonic_album_tile.dart';

class SonicAlbumList extends StatelessWidget {
  final List<Album> albums;

  SonicAlbumList(this.albums);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Albums'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: albums.length,
                itemBuilder: (context, i) {
                  final album = albums[i];

                  return SonicAlbumTile(
                    album,
                    onTap: () {
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
