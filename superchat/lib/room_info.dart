import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:superchat/chathome.dart';
import 'package:superchat/update_room.dart';


class RoomInfo extends StatelessWidget {
  final ChatHomeState chatHomeState;
  final User user;
  final model.Room room;
  const RoomInfo({Key key, this.chatHomeState, this.user, this.room}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: Text('Room Information'),
    ),
    body: SingleChildScrollView(child: Container(
      padding: EdgeInsets.all(30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text('Room name', style: TextStyle(color: Colors.blueAccent)), SizedBox(width: 10,), Text(room.name)],),
          Row(children: [Text('Room type', style: TextStyle(color: Colors.blueAccent)), SizedBox(width: 10,), Text(room.t)],),
          Row(children: [Text('Room description', style: TextStyle(color: Colors.blueAccent))]),
          Row(children: [SizedBox(width: 20), Text(room.description, textAlign: TextAlign.left,),]),
          Row(children: [Text('Room topic', style: TextStyle(color: Colors.blueAccent))]),
          Row(children: [SizedBox(width: 20), Text(room.topic, textAlign: TextAlign.left,),]),
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
                  editRoom(context);
                },
                child: Container(child:
                  Text('Edit')
                )
            ),
          ])
      ])
    )));
  }

  void editRoom(context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) =>
        UpdateRoom(key: updateRoomKey, chatHomeState: chatHomeState, user: user, room: room,)));
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

                    Navigator.pop(context, 'OK');
                  },
                ),
              ]
          );
        }
    );
    if (result == 'OK')
      Navigator.pop(context);
  }
}
