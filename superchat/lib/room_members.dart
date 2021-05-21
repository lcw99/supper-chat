import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/models/response/room_members_response.dart';

import 'utils/dialogs.dart';
import 'utils/utils.dart';
import 'widgets/userinfo.dart';

class RoomMembers extends StatefulWidget {
  final Room room;
  final Authentication authRC;
  const RoomMembers({Key key, this.room, this.authRC}) : super(key: key);

  @override
  _RoomMembersState createState() => _RoomMembersState();
}

class _RoomMembersState extends State<RoomMembers> {
  List<User> usersData;
  bool endOfData = false;
  bool refreshAll = false;
  bool getMoreData = false;
  int dataOffset = 0;
  int dataCount = 50;

  @override
  void initState() {
    usersData = [];
    endOfData = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Room Members')),
      body:
      Column(children: [
        //Container(height: 100, child:
        Expanded(flex: 1, child:
        FutureBuilder<List<User>>(
          future: getRoomMembers(dataOffset, dataCount),
          builder: (context, AsyncSnapshot snapshot){
            if (snapshot.hasData) {
              List<User> users = snapshot.data;
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
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    User user = users[index];
                    return GestureDetector(
                      onTap: () async {
                        var actionChild = InkWell(
                            onTap: () { Navigator.pop(context, 'kick.out.member'); },
                            child: Wrap(children: <Widget>[
                              Icon(Icons.remove_circle_outlined, color: Colors.redAccent), SizedBox(width: 5,),
                              Text('Kick out'),
                            ],)
                        );
                        String ret = await showDialogWithWidget(context, UserInfoWithAction(userInfo: user, actionChild: actionChild,), MediaQuery.of(context).size.height - 200);
                        if (ret != 'kick.out.member')
                          return;
                        var resp = await getChannelService().kickMember(widget.room, user.id, widget.authRC);
                        if (!resp.success) {
                          Utils.showToast('Kick out error : ${resp.body}');
                        } else
                          setState(() {
                            refreshAll = true;
                          });
                      },
                      child: Utils.buildUser(user, 40));
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

  Future<List<User>> getRoomMembers(int offset, int count) async {
    if (endOfData && !refreshAll)
      return usersData;
    if (refreshAll) {
      refreshAll = false;
      usersData.clear();
    }
    RoomMembersResponse r = await getChannelService().getRoomMembers(widget.room.id, widget.room.t, widget.authRC, offset: offset, count: count, sort: { "username": 1 });
    int ownerIndex = r.users.indexWhere((element) => element.id == widget.room.u.id);
    User owner;
    if (ownerIndex >= 0)
      owner = r.users.removeAt(ownerIndex);
    usersData.addAll(r.users);
    if (ownerIndex >= 0)
      usersData.insert(0, owner);
    if (r.total == r.offset + r.count)
      endOfData = true;
    return usersData;
  }
}
