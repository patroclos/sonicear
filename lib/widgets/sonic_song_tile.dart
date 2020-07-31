import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:sonicear/subsonic/models/song.dart';
import 'package:sonicear/widgets/sonic_cover.dart';

class SonicSongTile extends StatelessWidget {
  final Song song;
  final GestureTapCallback onTap;
  final GestureTapCallback onDoubleTap;
  final GestureLongPressCallback onLongPress;

  final Widget trailing;

  SonicSongTile(
    this.song, {
    @required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.trailing,
  }) : assert(song != null);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        onLongPress: onLongPress,
        child: Row(
          children: <Widget>[
            Expanded(
              flex: 1,
              child: SonicCover(
                song.coverArt,
                size: 35,
                child: Text(song.title),
              ),
            ),
            SizedBox(
              width: 12,
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${song.title}',
                    style: Theme.of(context).textTheme.subtitle1,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  if (song.artist != null)
                    Text(
                      '${song.artist.split(',')[0]}',
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                ],
              ),
            ),
            if (trailing != null)
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: trailing,
                ),
              )
          ],
        ),
      ),
    );
  }
}
