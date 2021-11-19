import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/models/response/receipt_response.dart';
import 'package:rocket_chat_connector_flutter/models/response/room_members_response.dart';
import 'package:superchat/chathome.dart';

import 'utils/utils.dart';

class ReadReceipt extends StatefulWidget {
  final Room room;
  final String messageId;
  final Authentication authRC;
  const ReadReceipt({Key key, this.room, this.messageId, this.authRC}) : super(key: key);

  @override
  ReadReceiptState createState() => ReadReceiptState();
}

class ReadReceiptState extends State<ReadReceipt> {
  List<User> readUsers = [];
  List<User> unreadUsers = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Read receipts')),
      body:FutureBuilder<bool>(
      future: getReadUnreadMembers(),
      builder: (context, AsyncSnapshot snapshot){
        if (snapshot.hasData) {
          return Column(children: [
            Container(child: Text('Read'), width: double.infinity,
              margin: EdgeInsets.only(left: 10),
              padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
              decoration: BoxDecoration(border: Border(left: BorderSide(width: 3, color: Colors.blueAccent))),),
            Expanded(flex: 3, child: buildUserList(readUsers)),
            Container(child: Text('Unread'), width: double.infinity,
              margin: EdgeInsets.only(left: 10),
              padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
              decoration: BoxDecoration(border: Border(left: BorderSide(width: 3, color: Colors.blueAccent ))),),
            Expanded(flex: 3, child: buildUserList(unreadUsers))
          ]);
        } else {
          return Center(child: CircularProgressIndicator(),);
        }
      })
    );
  }

  Widget buildUserList(List<User> users) {
    return ListView.builder(
      itemCount: users.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        User user = users[index];
        return GestureDetector(
          onTap: () { },
          child: Utils.buildUser(user, 40));
      }
    );
  }

  Future<bool> getReadUnreadMembers() async {
    RoomMembersResponse r = await getChannelService().getRoomMembers(widget.room.id, widget.room.t, widget.authRC, offset: 0, count: 100, sort: { "name": 1 });
    unreadUsers = r.users;
    ReceiptResponse rr = await getMessageService().getMessageReadReceipts(widget.messageId, widget.authRC);
    for (var r in rr.receipts) {
      readUsers.add(r.user);
      unreadUsers.removeWhere((element) => element.id == r.userId);
    }
    readUsers.removeWhere((element) => element.id == widget.authRC.data.me.id);
    unreadUsers.removeWhere((element) => element.id == widget.authRC.data.me.id);
    return true;
  }
}
