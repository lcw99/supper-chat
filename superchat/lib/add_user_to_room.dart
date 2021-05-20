import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/models/response/spotlight_response.dart';
import 'package:superchat/chathome.dart';

import 'utils/utils.dart';
import 'wigets/select_user.dart';

class AddUser extends StatefulWidget {
  final Room room;
  final Authentication authRC;
  const AddUser({Key key, this.room, this.authRC}) : super(key: key);

  @override
  _AddUserState createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  GlobalKey<SelectUserState> selectUserKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Users')),
      body:
      Column(children: [
        Expanded(child: SelectUser(key: selectUserKey, authRC: widget.authRC,)),
        TextButton(
          onPressed: () {
            List<String> users = selectUserKey.currentState.selectedUsers.map((x) => x.username).toList();
            getChannelService().addUsersToRoom(widget.room.id, users, widget.authRC);
            Navigator.pop(context);
          },
          child: Container(alignment: Alignment.centerLeft,
            padding: EdgeInsets.all(10),
            child: Text('Add'),
          ),
        ),
      ],
      ),
    );
  }
}
