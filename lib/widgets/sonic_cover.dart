import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sonicear/subsonic/requests/get_cover_art.dart';

enum CoverDisplayType { Circle, Square }

class SonicCover extends StatefulWidget {
  final String coverId;
  final double size;
  final Widget child;
  final CoverDisplayType displayType;

  SonicCover(
    this.coverId, {
    this.child,
    this.size = 100,
    this.displayType = CoverDisplayType.Square,
  }) : super(key: ValueKey('$coverId:$size'));

  @override
  _SonicCoverState createState() => _SonicCoverState();
}

class _SonicCoverState extends State<SonicCover> {
  Future<Uint8List> _imageBytesPromise;

  @override
  void initState() {
    super.initState();
    this._imageBytesPromise = widget.coverId != null
        ? GetCoverArt(
            widget.coverId,
            size: (widget.size * 2).round(),
          ).run(context.read()).then((data) => data.data)
        : Future.error('no coverid given');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageBytesPromise,
      builder: (context, snapshot) {
        ImageProvider image = snapshot.hasData
            ? MemoryImage(snapshot.data)
            : AssetImage('assets/blank_cover.png');
        return AspectRatio(
          aspectRatio: 1,
          child: _buildImage(image),
        );
      },
    );
  }

  Widget _buildImage(ImageProvider provider) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          image: DecorationImage(image: provider, fit: BoxFit.cover),
          shape: <CoverDisplayType, BoxShape>{
            CoverDisplayType.Square: BoxShape.rectangle,
            CoverDisplayType.Circle: BoxShape.circle,
          }[widget.displayType],
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(.5),
              spreadRadius: widget.size / 20,
              blurRadius: widget.size / 17,
              offset: Offset(0, 3).scale(widget.size / 100, widget.size / 100),
            )
          ],
        ),
      );
}
