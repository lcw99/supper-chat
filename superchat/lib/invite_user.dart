import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

import 'utils/utils.dart';

class AddUser extends StatefulWidget {
  final Authentication authRC;
  const AddUser({Key key, this.authRC}) : super(key: key);

  @override
  _AddUserState createState() => _AddUserState();
}

class _AddUserState extends State<AddUser> {
  DateTime from;
  List<User> users;
  List<User> selectedUsers = [];

  @override
  void initState() {
    from = DateTime.now().subtract(Duration(days: 30));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Invite Users')),
      body:
      Column(children: [
        Container(child: Text('Available'), width: double.infinity,
          margin: EdgeInsets.only(left: 10),
          padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
          decoration: BoxDecoration(border: Border(left: BorderSide(width: 3, color: Colors.blueAccent))),),
        Expanded(flex: 7, child:
        FutureBuilder<List<User>>(
        future: getUsersPresence(),
        builder: (context, AsyncSnapshot snapshot){
          if (snapshot.hasData) {
            users = snapshot.data;
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                User user = users[index];
                return GestureDetector(
                  onTap: () { setState(() {
                    selectedUsers.add(users.removeAt(index));
                  }); },
                  child: buildUser(user));
              }
            );
          } else {
            return Center(child: CircularProgressIndicator(),);
          }
        })),
        Container(child: Text('Selected'), width: double.infinity,
          margin: EdgeInsets.only(left: 10),
          padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
          decoration: BoxDecoration(border: Border(left: BorderSide(width: 3, color: Colors.blueAccent ))),),
        Expanded(flex: 3, child:
        ListView.builder(
          itemCount: selectedUsers.length,
          itemBuilder: (context, index) {
            User user = selectedUsers[index];
            return GestureDetector(
              onTap: () { setState(() {
                users.add(selectedUsers.removeAt(index));
              }); },
            child: buildUser(user));
          }
        )),
      ],
      ),
    );
  }

  buildUser(user) {
    return ListTile(
      dense: true,
      leading: Utils.buildUserAvatar(40, user),
      title: Text(
        Utils.getUserNameByUser(user) ,
        style: TextStyle(fontSize: 15, color: Colors.black),
        textAlign: TextAlign.left,
      ),
      subtitle: Text(
        user.username ,
        style: TextStyle(fontSize: 12, color: Colors.black54),
        textAlign: TextAlign.left,
      ),
    );
  }

  Future<List<User>> getUsersPresence() async {
    if (users != null)
      return Future.value(users);
    return getUserService().usersPresence(from, widget.authRC);
  }
}
