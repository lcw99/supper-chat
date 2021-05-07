import 'dart:io';

import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:superchat/chathome.dart';
import 'package:superchat/main.dart';
import 'package:superchat/update_room.dart';

import 'constants/constants.dart';


class RoomInfo extends StatefulWidget {
  final ChatHomeState chatHomeState;
  final User user;
  final String roomId;
  const RoomInfo({Key key, this.chatHomeState, this.user, this.roomId}) : super(key: key);

  @override
  _RoomInfoState createState() => _RoomInfoState();
}

class _RoomInfoState extends State<RoomInfo> {
  PickedFile newAvatar;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<model.Room>(
      future: getRoom(widget.roomId),
      builder: (context, AsyncSnapshot<model.Room> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return buildPage(context, snapshot.data);
        } else
          return SizedBox();
    });
  }

  Future<model.Room> getRoom(String roomId) {
    return widget.chatHomeState.getChannelService().getRoomInfo(roomId, widget.chatHomeState.widget.authRC);
  }

  Widget buildPage(context, model.Room room) {
    double imageWidth = MediaQuery.of(context).size.width;
    double imageHeight = imageWidth * 0.6;
    Widget avatar = Icon(Icons.no_photography_outlined, size: 100, color: Colors.blueAccent,);
    if (newAvatar != null)
      avatar = Image.file(File(newAvatar.path),
        fit: BoxFit.fitHeight,
        width: imageWidth,
        height: imageHeight,
        cacheWidth: 800,
        cacheHeight: 600,
      );
    else if (room.avatarETag != null)
      avatar = Image.network(serverUri.replace(path: '/avatar/room/${room.id}').toString(),
        fit: BoxFit.fitHeight,
        width: imageWidth,
        height: imageHeight,
      );
    return Scaffold(
        appBar: AppBar(
          title: Text('Room Information'),
        ),
        body: SingleChildScrollView(child: Container(
            padding: EdgeInsets.all(30),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(children: [
                    Container(height: imageHeight, width: imageWidth, alignment: Alignment.center, child: avatar),
                    Container(height: imageHeight, width: imageWidth, alignment: Alignment.bottomRight, child:
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                        InkWell(
                          onTap: () async {
                            newAvatar = await ImagePicker().getImage(source: ImageSource.gallery);
                            setState(() {});
                          },
                          child: DecoratedIcon(Icons.edit_outlined, color: Colors.blueAccent, size: 40,
                              shadows: [BoxShadow(color: Colors.black45, offset: Offset(3, 3))],),
                        ),
                        newAvatar != null ? InkWell(
                          onTap: () async {
                          },
                          child: DecoratedIcon(Icons.save_outlined, color: Colors.blueAccent, size: 40,
                              shadows: [BoxShadow(color: Colors.black45, offset: Offset(3, 3))],),
                        ) : SizedBox(),
                      ])
                    ),
                  ]),
                  TextFormField(
                    readOnly: true,
                    initialValue: room.name,
                    decoration: InputDecoration(
                      labelText: 'Room name',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextFormField(
                    readOnly: true,
                    initialValue: room.t == 'p' ? 'Private' : 'Public',
                    decoration: InputDecoration(
                      labelText: 'Room type',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextFormField(
                    maxLines: null,
                    readOnly: true,
                    initialValue: room.description,
                    decoration: InputDecoration(
                      labelText: 'Room description',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  TextFormField(
                    maxLines: null,
                    readOnly: true,
                    initialValue: room.topic,
                    decoration: InputDecoration(
                      labelText: 'Room topic',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10,),
                  Row(children: [
                    TextButton(
                        onPressed: () {
                          deleteRoom(context);
                        },
                        child: Container(child:
                        Text('Delete')
                        )
                    ),
                    TextButton(
                        onPressed: () {
                          editRoom(context, room);
                        },
                        child: Container(child:
                        Text('Edit')
                        )
                    ),
                  ])
                ])
        )));
  }

  Future<void> editRoom(context, room) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) =>
        UpdateRoom(key: updateRoomKey, chatHomeState: widget.chatHomeState, user: widget.user, room: room,)));
    setState(() {});
  }

  void deleteRoom(context) async {
    var result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Delete Room'),
              content: Text('Are you sure?'),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    chatHomeStateKey.currentState.deleteRoom(widget.roomId);
                    Navigator.pop(context, 'OK');
                  },
                ),
              ]
          );
        }
    );
    if (result == 'OK')
      Navigator.pop(context, 'room deleted');
  }
}
