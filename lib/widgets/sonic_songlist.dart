import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/provider/offline_cache.dart';
import 'package:sonicear/usecases/mediaitem_from_song.dart';
import 'package:sonicear/widgets/sonic_song_tile.dart';

// TODO: extract the list item into a sonic_song_tile and make multiple lists (eg. one browsing list, one queue management list, etc)
class SonicSonglist extends StatelessWidget {
  final List<DbSong> songs;
  final void Function(DbSong song) onTap;

  SonicSonglist(
    this.songs, {
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, i) {
        final song = songs[i];
        return SonicSongTile(
          song,
          onTap: () {
            onTap(song);
          },
          trailing: _buildPopupMenuButton(song, context),
        );
      },
      itemCount: songs.length,
    );
  }

  PopupMenuButton _buildPopupMenuButton(DbSong song, BuildContext context) {
    return PopupMenuButton(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Icon(Icons.menu),
      ),
      itemBuilder: (context) => <PopupMenuItem>[
        PopupMenuItem(
          child: Text('Play last'),
          value: 'play-last',
        ),
        PopupMenuItem(
          child: Text('Download'),
          value: 'download',
        ),
      ],
      onSelected: (item) async {
        switch (item) {
          case 'download':
            await context.read<OfflineCache>().makeAvailableOffline(song, context.read());
            // await downloadSong(song, context.read());
            break;
          case 'play-last':
            AudioService.addQueueItem(
                OnlineMediaItemFromSong(context.read())(song));
            break;
        }
      },
    );
  }
}
