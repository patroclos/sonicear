import 'package:flutter/foundation.dart';
import 'package:sonicear/subsonic/context.dart';

class SubsonicContextProvider with ChangeNotifier {
  SubsonicContext _context;
  SubsonicContext get context => _context;

  void updateContext(SubsonicContext context) {
    _context = context;
    notifyListeners();
  }
}