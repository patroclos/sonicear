import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/db/repository.dart';
import 'package:sonicear/provider/subsonic_context_provider.dart';
import 'package:sonicear/subsonic/context.dart';
import 'create_server_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Repository _repo;
  List<SubsonicContext> _servers;
  String _activeId;

  @override
  Widget build(BuildContext context) {
    if (_servers == null) {
      final Repository repo = context.watch();
      if (repo != null) {
        (() async {
          final servers = await repo.servers.listServers();
          final active = await repo.servers.getActiveServer();
          setState(() {
            _repo = repo;
            _servers = servers;
            _activeId = active?.serverId;
          });
        })();
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Subsonic Servers'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final toCreate = await Navigator.of(context).push<SubsonicContext>(
            MaterialPageRoute(
              builder: (context) => CreateServerScreen(),
            ),
          );

          if (toCreate != null) {
            final created = await _repo.servers.ensureServerExists(toCreate);
            setState(() {
              _servers.add(created);
            });
          }
        },
      ),
      body: Column(
        children: [
          if (_servers == null)
            CircularProgressIndicator()
          else
            Expanded(
              child: _serverList,
            ),
        ],
      ),
    );
  }

  Widget get _serverList => _servers == null
      ? CircularProgressIndicator()
      : ListView.builder(
          itemCount: _servers.length,
          itemBuilder: (context, idx) {
            final server = _servers[idx];

            return ListTile(
              title: Text(
                '${server.name}',
                style: Theme.of(context).textTheme.bodyText1.copyWith(
                      color: _activeId == server.serverId
                          ? Theme.of(context).accentColor
                          : null,
                    ),
              ),
              onTap: () async {
                await _repo.servers.setActiveServer(server);
                Provider.of<SubsonicContextProvider>(context, listen: false).updateContext(server);
                setState(() {
                  _activeId = server.serverId;
                });
              },
              trailing: PopupMenuButton<String>(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Text('Delete'),
                    value: 'delete',
                  )
                ],
                onSelected: (cmd) {
                  if (cmd == 'delete') deleteServer(server);
                },
              ),
            );
          },
        );

  void deleteServer(SubsonicContext server) async {
    assert(_repo != null);
    assert(server != null);
    await _repo.servers.delete(server);

    if(_activeId == server.serverId) {
      Provider.of<SubsonicContextProvider>(context, listen: false).updateContext(null);
    }
    setState(() {
      _servers..remove(server);
    });
  }
}
