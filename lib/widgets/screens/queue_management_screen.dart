import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/widgets/sonic_song_tile.dart';
import 'package:sonicear/usecases/extensions.dart';

class QueueManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final h6Style = Theme.of(context).textTheme.headline6;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),

        actions: [
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () async {
              await AudioService.updateQueue([]);
            },
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Text('Now Playing', style: h6Style),
              StreamBuilder<MediaItem>(
                stream: AudioService.currentMediaItemStream,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null)
                    return Text('nothing');

                  return SonicSongTile(
                    snapshot.data.extractDbSong(),
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
              Text('Coming Up', style: h6Style),
              StreamBuilder<List<DbSong>>(
                stream: AudioService.queueStream.map(
                    (lst) => lst.map((item) => item.extractDbSong()).toList()),
                initialData: AudioService.queue
                        ?.map((item) => item.extractDbSong())
                        ?.toList() ??
                    [],
                builder: (context, snapshot) {
                  if (snapshot.data == null) return Text('nothing');

                  return Expanded(
                    child: ListView.builder(
                      itemCount: snapshot.data.length,
                      itemBuilder: (context, idx) {
                        final song = snapshot.data[idx];
                        return SonicSongTile(
                          song,
                          onTap: () {
                            AudioService.skipToQueueItem(song.id);
                          },
                        );
                      },
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
