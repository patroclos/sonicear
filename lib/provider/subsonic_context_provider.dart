import 'package:flutter/foundation.dart';
import 'package:sonicear/db/dao/sqflite_server_dao.dart';
import 'package:sonicear/subsonic/context.dart';

class SubsonicContextProvider with ChangeNotifier {
  SubsonicContext _context;
  SubsonicContext get context => _context;

  void updateContext(SubsonicContext context) {
    _context = context;
    notifyListeners();
  }

  Future<void> initialize(SqfliteServerDao dao) async {
    final active = await dao.getActiveServer();

    if(active != null) {
      updateContext(active);
      return;
    }

    final servers = await dao.listServers();
    if(servers.isEmpty)
      return;

    await dao.setActiveServer(servers.first);
    updateContext(servers.first);
  }
}