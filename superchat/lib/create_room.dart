import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

import 'chathome.dart';

class CreateRoom extends StatefulWidget {
  final ChatHomeState chatHomeState;
  final User user;
  const CreateRoom({Key key, this.chatHomeState, this.user}) : super(key: key);

  @override
  CreateRoomState createState() => CreateRoomState();
}

class CreateRoomState extends State<CreateRoom> {
  TextEditingController _teController = TextEditingController();
  String errorText;
  String hintText = 'Room_Name';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Room'),
      ),
      body: Container(
      padding: EdgeInsets.all(30),
      child: Column(children: [
        TextFormField(
          autofocus: true,
          controller: _teController,
          keyboardType: TextInputType.text,
          maxLines: 1,
          decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
              helperText: 'alphanumeric, no space', hintText: hintText, errorText: errorText),
        ),
        InkWell(
          onTap: () {
            if (_teController.text == '')
              return;
            widget.chatHomeState.createRoom(_teController.text, [widget.user.username], true);
            //Navigator.pop(context);
          },
          child: Container(
            padding: EdgeInsets.all(12.0),
            child: Text('Update'),
          ),
        ),
      ])
    ));
  }

  onError(String errorMessage) {
    setState(() {
      errorText = errorMessage;
    });
  }

  void onOk(String roomName) {
    setState(() {
      errorText = '$roomName created';
    });
  }

  @override
  void dispose() {
    _teController.dispose();
    super.dispose();
  }

}
