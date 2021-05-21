import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/models/response/spotlight_response.dart';
import 'package:superchat/chathome.dart';

import 'utils/utils.dart';
import 'widgets/search_user.dart';
import 'widgets/select_user.dart';

class CreateDirectMessage extends StatefulWidget {
  final Authentication authRC;
  const CreateDirectMessage({Key key, this.authRC}) : super(key: key);

  @override
  _CreateDirectMessageState createState() => _CreateDirectMessageState();
}

class _CreateDirectMessageState extends State<CreateDirectMessage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Direct Message')),
      body:
      Column(children: [
        Expanded(child: SearchUser(authRC: widget.authRC, onUserSelected: userSelected,)),
      ],
      ),
    );
  }

  void userSelected(User user) {
    Navigator.pop(context, user);
  }
}
