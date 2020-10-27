import 'package:flutter/material.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/widgets/song_offline_switch.dart';

class SongContextSheet extends StatelessWidget {
  final DbSong song;

  SongContextSheet(this.song, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
        initialChildSize: .6,
        minChildSize: .4,
        maxChildSize: .8,
        expand: false,
        builder: (context, scrollController) => Material(
          elevation: 10,
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(12),
            child: FractionallySizedBox(
              widthFactor: 1,
              child: _content,
            ),
          ),
        ),
      );

  Widget get _content => Builder(
        builder: (context) => Column(
          children: [
            Text('${song.title}', style: Theme.of(context).textTheme.headline5),
            Text('${song.artist} on ${song.album}',
                style: Theme.of(context).textTheme.headline6),

            SongOfflineSwitch(song: song),
          ],
        ),
      );
}
