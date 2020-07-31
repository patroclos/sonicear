import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/audio/audio.dart';
import 'package:sonicear/usecases/mediaitem_from_song.dart';
import 'package:sonicear/widgets/sonic_song_tile.dart';
import '../subsonic/models/models.dart';

class SonicSearch extends StatefulWidget {
  final Future<Iterable<Song>> Function(String query) search;

  SonicSearch(this.search);

  @override
  _SonicSearchState createState() => _SonicSearchState();
}

class _SonicSearchState extends State<SonicSearch> {
  final TextEditingController _queryCtrl = TextEditingController();
  bool _searching = false;
  String _query = '';

  final items = <Song>[];

  @override
  void dispose() {
    super.dispose();
    _queryCtrl.dispose();
  }

  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[_searchField, _resultList],
    );
  }

  Widget get _title => Text('Browse Songs');

  Widget get _searchField =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 8),
        child: TextField(
          controller: _queryCtrl,
          autofocus: _query.isEmpty,
          decoration: InputDecoration(
            hintText: 'Search songs...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white30),
            icon: Icon(Icons.search),
            filled: true,
            fillColor: Colors.white30,
          ),
          // style: TextStyle(color: Colors.white, fontSize: 16),
          onChanged: (q) {
            updateSearchQuery(q);
          },
        ),
      );

  List<Widget> get _actions =>
      _searching
          ? <Widget>[
        IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            if (_queryCtrl.text.isEmpty) {
              Navigator.pop(context);
              return;
            }
            _clearSearchQuery();
          },
        )
      ]
          : <Widget>[
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: _startSearch,
        )
      ];

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
                  print(song);
                  playSong(song, OnlineMediaItemFromSong(context.read()));
                },
                trailing: PopupMenuButton<String>(
                  itemBuilder: (context) =>
                      ['Play Next', 'Play Last'].map((v) =>
                          PopupMenuItem(value: v, child: Text(v),)).toList(),
                  onSelected: (choice) {
                    final mediaItem = OnlineMediaItemFromSong(context.read())(
                        song);
                    switch (choice) {
                      case 'Play Next':
                        AudioService.addQueueItemAt(mediaItem, 0);
                        break;
                      case 'Play Last':
                        AudioService.addQueueItem(mediaItem);
                        break;
                    }
                  },
                ),
              );
            },
          ),
        ),
      );

  void _startSearch() async {
    ModalRoute.of(context)
        .addLocalHistoryEntry(LocalHistoryEntry(onRemove: _stopSearching));

    setState(() {
      _searching = true;
    });
  }

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
      print(items);
    });
  }

  void _stopSearching() {
    _clearSearchQuery();
    setState(() {
      _searching = false;
    });
  }

  void _clearSearchQuery() {
    setState(() {
      _queryCtrl.clear();
      updateSearchQuery('');
    });
  }
}
