import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:sonicear/audio/audio.dart';
import 'package:sonicear/db/dao/offline_cache_dao.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/provider/offline_cache.dart';
import 'package:sonicear/widgets/sonic_cover.dart';

class OfflineGallery extends StatefulWidget {
  final SqfliteSongDao songs;
  final SqfliteOfflineCacheDao cacheDao;

  OfflineGallery(this.songs, this.cacheDao)
      : assert(songs != null),
        assert(cacheDao != null);

  @override
  _OfflineGalleryState createState() => _OfflineGalleryState();
}

class _OfflineGalleryState extends State<OfflineGallery> {
  final _pagingController = PagingController<int, DbSong>(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) async {
      const pageSize = 10;
      final cacheSongs = await Future.wait(
        (await widget.cacheDao.list(count: pageSize, offset: pageKey)).map(
          (os) =>
              widget.songs.loadSong(serverId: os.serverId, songId: os.songId),
        ),
      );

      final isLast = cacheSongs.length < pageSize;
      if (isLast)
        _pagingController.appendLastPage(cacheSongs);
      else
        _pagingController.appendPage(cacheSongs, pageKey + pageSize);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView(
      scrollDirection: Axis.horizontal,
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<DbSong>(
          itemBuilder: (context, song, i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: InkWell(
                  onTap: () async {
                    await playSong(song, context.read());
                  },
                  child: SizedBox(
                    width: 120,
                    height: 140,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SonicCover(song.coverId,
                            size: 120, child: Text(song.title)),
                        SizedBox(height: 12),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${song.title}',
                              style: Theme.of(context).textTheme.subtitle1,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                            if (song.artist != null)
                              Text(
                                '${song.artist.split(',')[0]}',
                                style: Theme.of(context).textTheme.subtitle2,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
          )),
    );
  }
}
