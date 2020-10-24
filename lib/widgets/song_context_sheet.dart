import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:sonicear/audio/playback_utils.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';

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

            // TODO: hook this up to a Provider based download manager?
            // TODO: add more info, if we've just queued it or its in progress, like a label saying (x'th in queue, downloading, xx% downloaded, open folder)
            SwitchListTile(
              value: false,
              onChanged: (v) {
                print('available offline: $v');
              },
              title: Text('Available Offline'),
            ),
            OutlineButton(
              child: Text('Download'),
              onPressed: () {
                print('download $song');
                downloadSong(song, context.read());
                Navigator.of(context).pop();
              },
            )
          ],
        ),
      );
}
