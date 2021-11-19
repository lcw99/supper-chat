import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:superchat/constants/constants.dart';
import 'package:superchat/flatform_depended/platform_depended.dart';
import 'package:superchat/utils/utils.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoThumbnailView extends StatefulWidget {
  const VideoThumbnailView({Key key, this.videoFileName, this.width}) : super(key: key);
  final String videoFileName;
  final int width;

  @override
  _VideoThumbnailState createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnailView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getThumbnail(),
      builder: (context, AsyncSnapshot<Uint8List> snapShot) {
        if (snapShot.hasData) {
          if (snapShot.data.isEmpty)
            return SizedBox();
          return Container(child:
            Image.memory(snapShot.data, fit: BoxFit.contain,),
          );
        }
        return Center(child: CircularProgressIndicator());
      }
    );
  }

  Future<Uint8List> getThumbnail() async {
    String path = await fileExists(widget.videoFileName);
    if (path == null)
      return Uint8List(0);
    return VideoThumbnail.thumbnailData(
      video: path,
      imageFormat: ImageFormat.PNG,
      maxWidth: widget.width, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
      quality: 25,
    );
  }
}
