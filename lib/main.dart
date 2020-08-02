import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/audio/playback_utils.dart';
import 'package:sonicear/db/appdb.dart';
import 'package:sonicear/db/repository.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/subsonic.dart';
import 'package:sonicear/subsonic/requests/requests.dart' as sub_req;
import 'package:sonicear/usecases/mediaitem_from_song.dart';
import 'package:sonicear/usecases/search_music.dart';
import 'package:sonicear/widgets/playback_line.dart';
import 'package:sonicear/widgets/sonic_albumlist.dart';
import 'package:sonicear/widgets/sonic_playback.dart';
import 'package:sonicear/widgets/sonic_search.dart';
import 'package:sonicear/widgets/sonic_songlist.dart';
import 'package:sonicear/usecases/extensions.dart';

import 'package:flutter_downloader/flutter_downloader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
    debug: true,
  );

  runApp(SonicEarApp());
}

final devMemoryServer = SubsonicContext(
  serverId: '--dev-memory-server--',
  endpoint: Uri(
      scheme: 'http', host: '192.168.2.106', port: 8080, path: '/airsonic/'),
  name: 'Development Server',
  user: 'app',
  pass: 'sonicear',
);

class SonicEarApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final repoPromise = AppDb.instance.database.then(
        createSqfliteRepository); //createSqfliteRepository(await AppDb.instance.database);
    return MultiProvider(
      providers: [
        FutureProvider(create: (context) async {
          await (await repoPromise).servers.ensureServerExists(devMemoryServer);

          return devMemoryServer;
        }),
        FutureProvider(
          create: (_) => repoPromise,
        )
      ],
      child: MaterialApp(
        title: 'Sonic Ear',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
          ),
        ),
        home: AudioServiceWidget(
          child: MainAppScreen(),
        ),
      ),
    );
  }
}

class MainAppScreen extends StatefulWidget {
  MainAppScreen({Key key}) : super(key: key);

  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _selectedNav = 0;

  final areas = <Widget>[
    Builder(builder: (context) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () {
                  // TODO: open settings page for configuring servers, etc
                },
              ),
            ],
          ),
          FlatButton(
            child: Text('Random Songs'),
            onPressed: () async {
              final ctx = context.read<SubsonicContext>();
              final songs = (await sub_req.GetRandomSongs(size: 30).run(ctx))
                  .data
                  .map((song) => song.toDbSong())
                  .toList();

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(
                      title: Text('Random Songs'),
                      actions: <Widget>[
                        IconButton(
                          icon: Icon(Icons.shuffle),
                          onPressed: () {
                            AudioService.updateQueue(
                              songs
                                  .map(OnlineMediaItemFromSong(ctx).call)
                                  .toList(),
                            );
                          },
                        )
                      ],
                    ),
                    body: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SonicSonglist(
                        songs,
                        onTap: (song) {
                          playSong(
                              song, OnlineMediaItemFromSong(context.read()));
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => SonicPlayback()));
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          /*
          FlatButton(
            child: Text('Albums'),
            onPressed: () async {
              final ctx = context.read<SubsonicContext>();
              // TODO: how do we do paging?
              final albums = await sub_req.GetAlbumList(
                      type: 'alphabeticalByArtist', size: 200)
                  .run(ctx);

              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SonicAlbumList(albums.data),
                ),
              );
            },
          ),
          */
        ],
      );
    }),
    Builder(
      builder: (context) => SonicSearch(SearchMusic.of(context)),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNav,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.library_music), title: Text('Library')),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), title: Text('Search'))
        ],
        onTap: (selected) {
          setState(() {
            _selectedNav = selected;
          });
        },
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: IndexedStack(
                  children: areas
                      .asMap()
                      .entries
                      .map((kv) => ExcludeFocus(
                            child: kv.value,
                            excluding: _selectedNav != kv.key,
                          ))
                      .toList(),
                  index: _selectedNav,
                ),
              ),
              Align(
                child: PlaybackLine(),
                alignment: Alignment.bottomCenter,
              )
            ],
          ),
        ),
      ),
    );
  }
}
