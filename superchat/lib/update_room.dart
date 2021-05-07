import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;

import 'chathome.dart';

class UpdateRoom extends StatefulWidget {
  final ChatHomeState chatHomeState;
  final User user;
  final model.Room room;
  const UpdateRoom({Key key, this.chatHomeState, this.user, this.room}) : super(key: key);

  @override
  UpdateRoomState createState() => UpdateRoomState();
}

class UpdateRoomState extends State<UpdateRoom> {
  TextEditingController _tecRoomName = TextEditingController();
  TextEditingController _tecRoomDescription = TextEditingController();
  TextEditingController _tecRoomTopic = TextEditingController();
  String errorText;
  String hintText = 'Room_Name';
  String helperText = 'alphanumeric, no space';
  bool roomCreated = false;

  bool isPrivate = true;

  static const String createRoomText = "Create Room";
  static const String updateRoomText = "Update Room";
  String buttonText = createRoomText;
  String createdRoomId;

  int updateCallCount;

  String errorTextRoomTopic;

  bool editMode = false;

  StreamSubscription streamSub;

  @override
  void initState() {
    editMode = widget.room != null;
    buttonText = editMode ? updateRoomText : createRoomText;
    createdRoomId = editMode ? widget.room.id : null;

    if (editMode) {
      _tecRoomName.text = widget.room.name;
      _tecRoomDescription.text = widget.room.description;
      _tecRoomTopic.text = widget.room.topic;
      isPrivate = widget.room.t == 'c' ? false : true;
    }

    streamSub = resultMessageController.stream.listen((event) {
      onEvent(event);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(editMode ? updateRoomText : createRoomText),
      ),
      body: SingleChildScrollView(child: Container(
      padding: EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        TextFormField(
          autofocus: true,
          readOnly: roomCreated,
          controller: _tecRoomName,
          keyboardType: TextInputType.text,
          maxLines: 1,
          decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
              helperText: helperText, hintText: hintText, errorText: errorText),
        ),
        SizedBox(height: 15,),
        ToggleSwitch(
          initialLabelIndex: isPrivate ? 0 : 1,
          minWidth: 110.0,
          minHeight: 35,
          cornerRadius: 8.0,
          activeBgColor: Colors.cyan,
          activeFgColor: Colors.white,
          inactiveBgColor: Colors.grey,
          inactiveFgColor: Colors.white,
          labels: ['Private', 'Public'],
          fontSize: 12,
          icons: [Icons.lock, Icons.public],
          onToggle: (index) {
            if (index == 0)
              isPrivate = true;
            else
              isPrivate = false;
          },
        ),
        roomCreated || editMode ? Column(
          children: [
          SizedBox(height: 10,),
          TextFormField(
            autofocus: true,
            controller: _tecRoomDescription,
            keyboardType: TextInputType.text,
            maxLines: 3,
            decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
                helperText: 'Room description', ),
          ),
          SizedBox(height: 10,),
          TextFormField(
            autofocus: true,
            controller: _tecRoomTopic,
            keyboardType: TextInputType.text,
            maxLines: 3,
            decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
                helperText: 'Room topic', errorText: errorTextRoomTopic),
          ),
        ]) : SizedBox(),
        TextButton(
          onPressed: () {
            if (_tecRoomName.text.isEmpty)
              return;
            if (buttonText == 'Create Room')
              widget.chatHomeState.createRoom(_tecRoomName.text, [widget.user.username], isPrivate);
            else if (buttonText == 'Update Room') {
              updateCallCount = 0;
              if (editMode) {
                if (_tecRoomName.text.isNotEmpty) {
                  widget.chatHomeState.updateRoom(createdRoomId, roomName: _tecRoomName.text);
                  updateCallCount++;
                }
                widget.chatHomeState.updateRoom(createdRoomId, roomType: isPrivate ? 'p' : 'c');
                updateCallCount++;
              }
              widget.chatHomeState.updateRoom(createdRoomId, roomTopic: _tecRoomTopic.text);
              updateCallCount++;
              widget.chatHomeState.updateRoom(createdRoomId, roomDescription: _tecRoomDescription.text);
              updateCallCount++;
            }
            //Navigator.pop(context);
          },
          child: Container(
            padding: EdgeInsets.zero,
            child: Text(buttonText),
          ),
        ),
      ])
    )));
  }

  onEvent(rocket_notification.Notification event) {
    if (event.id == '85' || event.id == '89') { // 85: createChannel, 89: createPrivateGroup,
      if (event.error != null) {
        setState(() {
          errorText = event.error.reason;
        });
      }
      if (event.result != null) {
        createdRoomId = event.result['rid'];
        setState(() {
          roomCreated = true;
          errorText = null;
          helperText = '${event.result['name']} created';
          buttonText = updateRoomText;
        });
      }
    } else if (event.id == '16') { // 16: update room
      if (event.result != null && event.result['result']) {
        updateCallCount--;
        if (updateCallCount == 0) {
          Navigator.pop(context);
        }
      } else {
        if (event.error != null) {
          setState(() {
            errorTextRoomTopic = event.error.reason;
          });
        } else {
          setState(() {
            errorTextRoomTopic = 'Room update error.';
          });
        }
      }
    }
  }

  @override
  void dispose() {
    streamSub.cancel();
    _tecRoomName.dispose();
    super.dispose();
  }

}
