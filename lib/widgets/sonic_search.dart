import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/audio/audio.dart';
import 'package:sonicear/db/dao/sqflite_song_dao.dart';
import 'package:sonicear/usecases/mediaitem_from_song.dart';
import 'package:sonicear/widgets/song_context_sheet.dart';
import 'package:sonicear/widgets/sonic_song_tile.dart';

class SonicSearch extends StatefulWidget {
  final Future<Iterable<DbSong>> Function(String query) search;

  SonicSearch(this.search);

  @override
  _SonicSearchState createState() => _SonicSearchState();
}

class _SonicSearchState extends State<SonicSearch> {
  final TextEditingController _queryCtrl = TextEditingController();
  final FocusNode _focus = FocusNode(
    debugLabel: 'SearchField Focus',
  );

  String _query = '';

  final items = <DbSong>[];

  @override
  void dispose() {
    super.dispose();
    _queryCtrl.dispose();
    _focus.dispose();
  }

  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[_searchField, _resultList],
    );
  }

  Widget get _searchField =>
      Padding(
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
              onPressed: () => _queryCtrl.clear(),
            ),
            filled: true,
            fillColor: Colors.white30,
          ),
          onChanged: (q) {
            updateSearchQuery(q);
          },
        ),
      );

  Widget get _resultList =>
      Expanded(
        child: Scrollbar(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final song = items[i];

              return SonicSongTile(
                song,
                onTap: () {
                  _focus.unfocus();
                  final mediaItem = CachedOrOnlineMediaItemFromSong(context.read(), context.read());
                  playSong(song, mediaItem);
                },
                trailing: IconButton(
                  icon: Icon(Icons.more_vert),
                  onPressed: () async {
                    _focus.unfocus();
                    Scaffold.of(context).showBottomSheet((context) => SongContextSheet(song));
                  },
                ),
                  /*
                trailing: PopupMenuButton<String>(
                  itemBuilder: (context) =>
                      ['Play Next', 'Play Last'].map((v) =>
                          PopupMenuItem(value: v, child: Text(v),)).toList(),
                  onSelected: (choice) {
                    final mediaItem = OnlineMediaItemFromSong(context.read())(
                        song);
                    switch (choice) {
                      case 'Play Next':
                        AudioService.addQueueItemAt(mediaItem, 1);
                        break;
                      case 'Play Last':
                        AudioService.addQueueItem(mediaItem);
                        break;
                    }
                  },
                ),
                */
              );
            },
          ),
        ),
      );

  void updateSearchQuery(String newQuery) async {
    setState(() {
      _query = newQuery;
    });

    final q = _query;
    final results = await widget.search(q);

    if(q != _query)
      return;

    setState(() {
      items.clear();
      items.addAll(results);
    });
  }

}
