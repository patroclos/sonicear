import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:sonicear/subsonic/models/models.dart';
import 'package:sonicear/widgets/sonic_cover.dart';

class SonicAlbumTile extends StatelessWidget {
  final Album album;
  final GestureTapCallback onTap;
  final GestureTapCallback onDoubleTap;
  final GestureLongPressCallback onLongPress;

  final Widget trailing;

  SonicAlbumTile(
    this.album, {
    @required this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.trailing,
  }) : assert(album != null);

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
                album.coverArt,
                size: 35,
                child: Text(album.title),
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
                    '${album.title}',
                    style: Theme.of(context).textTheme.subtitle1,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                  if (album.artist != null)
                    Text(
                      '${album.artist.split(',')[0]}',
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
