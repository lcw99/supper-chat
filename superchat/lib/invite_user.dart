import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

class InviteUser extends StatefulWidget {
  final Authentication authRC;
  const InviteUser({Key key, this.authRC}) : super(key: key);

  @override
  _InviteUserState createState() => _InviteUserState();
}

class _InviteUserState extends State<InviteUser> {
  DateTime from;

  @override
  void initState() {
    from = DateTime.now().subtract(Duration(days: 30));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getUserService().usersPresence(from, widget.authRC),
      builder: (context, AsyncSnapshot snapshot){
        if (snapshot.hasData) {
          List<User> users = snapshot.data;
          return Scaffold(
            appBar: AppBar(title: Text('Invite User')),
            body: Column(children: [
              ListView.builder(itemBuilder: (context, index) {
                return ListTile(
                  leading: SizedBox(),
                );
              }),
            ]),
          );
        } else {
          return SizedBox();
        }
      });
  }
}
