import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/audio/audio.dart';
import 'package:sonicear/audio/playback_utils.dart';
import 'package:sonicear/db/appdb.dart';
import 'package:sonicear/db/offline_cache.dart';
import 'package:sonicear/db/repository.dart';
import 'package:sonicear/provider/subsonic_context_provider.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/subsonic.dart';
import 'package:sonicear/subsonic/requests/requests.dart' as sub_req;
import 'package:sonicear/usecases/mediaitem_from_song.dart';
import 'package:sonicear/usecases/search_music.dart';
import 'package:sonicear/widgets/playback_line.dart';
import 'package:sonicear/widgets/settings_screen.dart';
import 'package:sonicear/widgets/sonic_search.dart';
import 'package:sonicear/widgets/sonic_songlist.dart';
import 'package:sonicear/usecases/extensions.dart';

import 'package:flutter_downloader/flutter_downloader.dart';

final repoPromise = AppDb.instance.database.then(createSqfliteRepository);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
    debug: true,
  );
  final repo = await repoPromise;
  OfflineCache.init(repo.offlineCache);
  AudioServiceLoopMode.connect();

  runApp(SonicEarApp());
}

SubsonicContextProvider createContextProvider(){
  final provider = SubsonicContextProvider();

  repoPromise.then((repo) async {
    final dao = repo.servers;
    final active = await dao.getActiveServer();
    if(active != null)
      provider.updateContext(active);

    final servers = await dao.listServers();
    if(servers.isEmpty) return;

    await dao.setActiveServer(servers.first);
    provider.updateContext(servers.first);
  });

  return provider;
}

class SonicEarApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MultiProvider(
      providers: [
        FutureProvider(
          create: (_) => repoPromise,
        ),
        ChangeNotifierProvider(create: (context) => createContextProvider()),
        ProxyProvider<SubsonicContextProvider, SubsonicContext>(
          update: (ctx, a, b) => a.context
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
    // TODO: make this a widget
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
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
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
                            song,
                            OnlineMediaItemFromSong(context.read()),
                          );
                          /*
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => SonicPlayback()));
                           */
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
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
              icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Search')
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
