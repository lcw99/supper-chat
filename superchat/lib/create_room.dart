import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:toggle_switch/toggle_switch.dart';

import 'chathome.dart';

class CreateRoom extends StatefulWidget {
  final ChatHomeState chatHomeState;
  final User user;
  const CreateRoom({Key key, this.chatHomeState, this.user}) : super(key: key);

  @override
  CreateRoomState createState() => CreateRoomState();
}

class CreateRoomState extends State<CreateRoom> {
  TextEditingController _tecRoomName = TextEditingController();
  TextEditingController _tecRoomDescription = TextEditingController();
  TextEditingController _tecRoomTopic = TextEditingController();
  String errorText;
  String hintText = 'Room_Name';
  String helperText = 'alphanumeric, no space';
  bool roomCreated = false;

  bool isPrivate = true;
  String buttonText = "Create Room";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Room'),
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
        roomCreated ? Column(
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
                helperText: 'Room topic'),
          ),
        ]) : SizedBox(),
        TextButton(
          onPressed: () {
            if (_tecRoomName.text.isEmpty)
              return;
            if (buttonText == 'Create Room')
              widget.chatHomeState.createRoom(_tecRoomName.text, [widget.user.username], isPrivate);
            else if (buttonText == 'Update Room')
              {}
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

  onError(String errorMessage) {
    setState(() {
      errorText = errorMessage;
    });
  }

  void onOk(String roomName) {
    setState(() {
      roomCreated = true;
      errorText = null;
      helperText = '$roomName created';
      buttonText = 'Update Room';
    });
  }

  @override
  void dispose() {
    _tecRoomName.dispose();
    super.dispose();
  }

}
