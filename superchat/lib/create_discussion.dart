import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

import 'widgets/select_user.dart';

class CreateDiscussion extends StatefulWidget {
  const CreateDiscussion({Key key, this.parentRoomId, this.parentMessageId, this.authRC}) : super(key: key);

  final String parentRoomId;
  final String parentMessageId;
  final Authentication authRC;

  @override
  _CreateDiscussionState createState() => _CreateDiscussionState();
}

class _CreateDiscussionState extends State<CreateDiscussion> {
  GlobalKey<SelectUserState> selectUserKey = GlobalKey();
  String discussionName;
  String errorText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Create Discussion')),
    body:
      Column(children: [
      Container(child: TextFormField(
        autofocus: true,
        keyboardType: TextInputType.text,
        maxLines: 1,
        decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
            helperText: 'Discussion room name', errorText: errorText),
        onChanged: (value) {
          discussionName = value;
          setState(() {
            errorText = null;
          });
        },
      ), margin: EdgeInsets.all(15)),
      Expanded(child: SelectUser(key: selectUserKey, authRC: widget.authRC,)),
      TextButton(
        onPressed: () {
          List<String> users = selectUserKey.currentState.selectedUsers.map((x) => x.username).toList();
          if (discussionName == null || discussionName.isEmpty) {
            setState(() {
              errorText = 'Required';
            });
            return;
          }
          getChannelService().createDiscussion(widget.parentRoomId, discussionName, users, widget.parentMessageId, widget.authRC);
          Navigator.pop(context);
        },
        child: Container(alignment: Alignment.centerLeft,
          padding: EdgeInsets.all(10),
          child: Text('Create'),
        ),
      ),
    ]));
  }
}
