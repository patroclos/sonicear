import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/audio/audio.dart';
import 'package:sonicear/audio/playback_utils.dart';
import 'package:sonicear/db/appdb.dart';
import 'package:sonicear/db/repository.dart';
import 'package:sonicear/provider/loopmode_provider.dart';
import 'package:sonicear/provider/offline_cache.dart';
import 'package:sonicear/provider/subsonic_context_provider.dart';
import 'package:sonicear/subsonic/context.dart';
import 'package:sonicear/subsonic/subsonic.dart';
import 'package:sonicear/subsonic/requests/requests.dart' as sub_req;
import 'package:sonicear/usecases/mediaitem_from_song.dart';
import 'package:sonicear/usecases/search_music.dart';
import 'package:sonicear/widgets/offline_gallery.dart';
import 'package:sonicear/widgets/playback_line.dart';
import 'package:sonicear/widgets/screens/settings_screen.dart';
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

class SonicEarApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        FutureProvider<Repository>(
          create: (_) async =>
              createSqfliteRepository(await AppDb.instance.database),
        ),
        ChangeNotifierProxyProvider<Repository, SubsonicContextProvider>(
            create: (_) => SubsonicContextProvider(),
            update: (_, repo, provider) {
              if (repo != null) provider.initialize(repo.servers);
              return provider;
            }),
        ProxyProvider<SubsonicContextProvider, SubsonicContext>(
          update: (ctx, a, b) => a.context,
        ),
        ChangeNotifierProvider(create: (_) => LoopModeProvider()),
        ProxyProvider<LoopModeProvider, LoopMode>(
          update: (_, lmp, __) => lmp.mode,
        ),
        ChangeNotifierProxyProvider<Repository, OfflineCache>(
          create: (_) => OfflineCache(),
          update: (_, Repository r, not) => not..setDao(r.offlineCache),
        ),
        ProxyProvider2<SubsonicContext, Repository, SearchMusic>(
          update: (_, server, repo, oldValue) => server != null && repo != null
              ? SearchMusic(server, repo)
              : oldValue,
        ),
        ProxyProvider2<SubsonicContext, OfflineCache, MediaItemFromSong>(
          update: (_, server, cache, oldValue) =>
              server != null && cache != null
                  ? CachedOrOnlineMediaItemFromSong(cache, server)
                  : oldValue,
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

  Widget get _settingsRow => Row(
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
  );

  List<Widget> get areas => <Widget>[
    // TODO: make this a widget
    Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _settingsRow,
            Text('Offline Songs', style: Theme.of(context).textTheme.headline5),
            SizedBox(
              height: 200,
              child: Builder(builder: (context) {
                final repo = context.watch<Repository>();
                if(repo == null)
                  return CircularProgressIndicator();
                return OfflineGallery(repo.songs, repo.offlineCache);
              }),
            ),
            Expanded(
              child: Column(
                children: [
                  FlatButton(
                    child: Text('Random Songs'),
                    onPressed: () async {
                      final ctx = context.read<SubsonicContext>();
                      final songs =
                          (await sub_req.GetRandomSongs(size: 30).run(ctx))
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
                                  playSong(song, context.read());
                                },
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }),
    Builder(
      builder: (context) => SonicSearch(),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNav,
        items: [
          BottomNavigationBarItem(
            label: 'Library',
            icon: Icon(Icons.library_music),
          ),
          BottomNavigationBarItem(
            label: 'Search',
            icon: Icon(Icons.search),
          )
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
