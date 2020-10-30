import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/provider/offline_cache.dart';

class SongOfflineSwitch extends StatelessWidget {
  final DbSong song;

  SongOfflineSwitch({
    @required this.song,
    Key key,
  }) : super(key: key ?? ValueKey('${song.serverId}_${song.id}'));

  @override
  Widget build(BuildContext context) {
    final taskProgress = context.select<OfflineCache, int>((cache) =>
        cache.hasCachingTask(song) ? cache.getTaskProgress(song) : null);
    final isCached = context.select<OfflineCache, Future<bool>>(
      (cache) async =>
          cache.hasCachingTask(song) || await cache.getCachedSong(song) != null,
    );
    return FutureBuilder(
      future: isCached,
      builder: (context, snapshot) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            title: Text('Available Offline'),
            value: snapshot.hasData ? snapshot.data : false,
            onChanged: taskProgress != null ? null : (value) async {
              final cache = context.read<OfflineCache>();
              await (value
                  ? cache.makeAvailableOffline(song, context.read())
                  : cache.evict(song));
            },
          ),
          if (taskProgress != null) ...[
            LinearProgressIndicator(value: taskProgress / 100.0),
            Text('Download Progress: $taskProgress%'),
          ],
        ],
      ),
    );
  }
}
