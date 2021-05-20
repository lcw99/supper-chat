import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/models/response/rcfile_response.dart';
import 'package:rocket_chat_connector_flutter/models/rc_file.dart';
import 'widgets/full_screen_image.dart';

import 'constants/constants.dart';
import 'utils/utils.dart';

class RoomFiles extends StatefulWidget {
  final Room room;
  final Authentication authRC;
  const RoomFiles({Key key, this.room, this.authRC}) : super(key: key);

  @override
  _RoomFilesState createState() => _RoomFilesState();
}

class _RoomFilesState extends State<RoomFiles> {
  List<RcFile> filesData;
  bool endOfData = false;
  bool getMoreData = false;
  int dataOffset = 0;
  int dataCount = 50;
  bool imageDisplay = true;

  @override
  void initState() {
    filesData = [];
    endOfData = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text('Room Files'),
        actions: [
          IconButton(
            icon: imageDisplay ? Icon(Icons.image_not_supported_outlined) : Icon(Icons.image_outlined),
            onPressed: () {
              setState(() {
                imageDisplay = !imageDisplay;
              });
            },
          ),
        ],
      ),
      body:
      Column(children: [
        //Container(height: 100, child:
        Expanded(flex: 1, child:
        FutureBuilder<List<RcFile>>(
            future: getRoomFiles(dataOffset, dataCount),
            builder: (context, AsyncSnapshot snapshot){
              if (snapshot.hasData) {
                List<RcFile> files = snapshot.data;
                return NotificationListener<ScrollEndNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.atEdge) {
                        print('*****listview Scroll end = ${notification.metrics.pixels}');
                        if (!endOfData && notification.metrics.pixels != notification.metrics.minScrollExtent) { // bottom
                          print('!!! scrollview hit bottom');
                          setState(() {
                            getMoreData = true;
                            dataOffset += dataCount;
                          });
                        }
                      }
                      return true;
                    },
                    child: ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (context, index) {
                          RcFile file = files[index];
                          if (!imageDisplay && file.typeGroup == 'image')
                            return SizedBox();
                          return GestureDetector(
                              onTap: () {  },
                              child: buildFile(file, 40));
                        }
                      )
                );
              } else {
                return Center(child: CircularProgressIndicator(),);
              }
            })),
      ]),
    );
  }

  Future<List<RcFile>> getRoomFiles(int offset, int count) async {
    if (endOfData)
      return filesData;
    RcFileResponse r = await getChannelService().getFiles(widget.room, widget.authRC, offset: offset, count: count, sort: { "uploadedAt": -1 });
    filesData.addAll(r.files);
    if (r.total == r.offset + r.count)
      endOfData = true;
    return filesData;
  }

  buildFile(RcFile file, double size) {
    User user = file.user;
    Color userNameColor = Colors.black;
    var usernameFontSize = USERNAME_FONT_SIZE;
    String dateStr = Utils.getDateString(file.uploadedAt);
    return Container(child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Utils.buildUserAvatar(size, user),
      SizedBox(width: 5,),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(children: [
          Text(
            Utils.getUserNameByUser(user),
            style: TextStyle(fontSize: usernameFontSize, color: userNameColor),
            textAlign: TextAlign.left,
          ),
          Expanded(child: Container(child:
          Text(dateStr, style: TextStyle(fontSize: usernameFontSize, color: Colors.blueGrey, fontStyle: FontStyle.italic),),
            alignment: Alignment.centerRight,
          )),
        ]),
        Container(child: LayoutBuilder(builder: (context, boxConstraint) {
          return Container(child: buildSubtitle(file, boxConstraint.maxWidth), padding: EdgeInsets.only(top: 5));
        })),
      ]))
    ]), padding: EdgeInsets.all(10),);
  }

  Widget buildSubtitle(RcFile file, double renderWidth) {
    if (file.typeGroup == 'image') {
      return Column(children: [
        FullScreenWidget(
          child: Hero(
            tag: file.id,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Utils.buildImageByLayout(widget.authRC, file.path, renderWidth, file.identify.size),
            ),
          ),
        ),
        GestureDetector(child: Row(children: [
          Expanded(child: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis,)),
          SizedBox(width: 10,),
          Icon(Icons.download_sharp, color: Colors.blueAccent,),
        ],),
          onTap: () {
            Utils.downloadFile(widget.authRC, file.path);
          },
        )
      ],);
    } else {
      return GestureDetector(child: Row(children: [
        Text(file.name),
        SizedBox(width: 10,),
        Icon(Icons.download_sharp, color: Colors.blueAccent,),
        ],),
        onTap: () {
          Utils.downloadFile(widget.authRC, file.path);
        },
      );
    }
  }
}
