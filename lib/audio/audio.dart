export 'music_background_task.dart';
export 'playable_song.dart';
export 'playback_utils.dart';

// subsonic_song -> [db, playable_media]
// db -> playable_media
// db -> file -> playable_media

import 'package:bloc/bloc.dart';

class SongState {
  String uuid;
  String subsonicId;
}

class SongBloc extends Bloc<Map<String, dynamic>, SongState> {
  SongBloc(SongState initialState) : super(initialState);

  @override
  Stream<SongState> mapEventToState(Map<String, dynamic> event) {
    switch(event['cmd']) {
      case 'download':
        break;
      case 'evict':
        break;
    }
  }

}