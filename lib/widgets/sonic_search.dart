import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/audio/audio.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/subsonic/requests/requests.dart';
import 'package:sonicear/usecases/mediaitem_from_song.dart';
import 'package:sonicear/usecases/search_music.dart';
import 'package:sonicear/widgets/song_context_sheet.dart';
import 'package:sonicear/widgets/sonic_song_tile.dart';

class SonicSearch extends StatefulWidget {
  // final Future<Iterable<DbSong>> Function(String query) searchSongs;
  final int batchSize;

  SonicSearch({this.batchSize = 20});

  @override
  _SonicSearchState createState() => _SonicSearchState();
}

class _SonicSearchState extends State<SonicSearch> {
  final TextEditingController _queryCtrl = TextEditingController();
  final FocusNode _focus = FocusNode(
    debugLabel: 'SearchField Focus',
  );

  String _query = '';

  final _pagingController = PagingController<int, DbSong>(firstPageKey: 0);

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener((pageOffset) async {
      try {
        final result = (await context.read<SearchMusic>().call(
                  this._query,
                  song:
                      CountOffset(count: widget.batchSize, offset: pageOffset),
                ))
            .toList();

        final isLast = result.length < widget.batchSize;
        if (isLast)
          _pagingController.appendLastPage(result);
        else {
          final nextKey = pageOffset + result.length;
          _pagingController.appendPage(result, nextKey);
        }
      } catch (e, trace) {
        print('$e\n\n$trace');
        _pagingController.error = e;
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _queryCtrl.dispose();
    _focus.dispose();
  }

  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[_searchField, if(context.watch<SearchMusic>() != null) _resultList],
    );
  }

  Widget get _searchField => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 8),
        child: TextField(
          controller: _queryCtrl,
          focusNode: _focus,
          keyboardType: TextInputType.text,
          decoration: InputDecoration(
            hintText: 'Search songs...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white30),
            icon: Icon(Icons.search),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                _queryCtrl.clear();
                updateSearchQuery('');
              },
            ),
            filled: true,
            fillColor: Colors.white30,
          ),
          onChanged: (q) {
            updateSearchQuery(q);
          },
        ),
      );

  Widget get _resultList => Expanded(
        child: Scrollbar(
          child: PagedListView<int, DbSong>(
              pagingController: _pagingController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              builderDelegate: PagedChildBuilderDelegate<DbSong>(
                itemBuilder: (context, song, index) => SonicSongTile(
                  song,
                  onTap: () {
                    _focus.unfocus();
                    final resolveMediaItem = CachedOrOnlineMediaItemFromSong(
                        context.read(), context.read());
                    playSong(song, resolveMediaItem);
                  },
                  trailing: IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () async {
                      _focus.unfocus();
                      Scaffold.of(context)
                          .showBottomSheet((context) => SongContextSheet(song));
                    },
                  ),
                ),
              )),
        ),
      );

  void updateSearchQuery(String newQuery) async {
    setState(() {
      _query = newQuery;
    });

    _pagingController.refresh();
  }
}
