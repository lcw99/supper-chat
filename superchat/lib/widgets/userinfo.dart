import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:superchat/utils/utils.dart';

class UserInfo extends StatefulWidget {
  final User userInfo;
  const UserInfo({Key key, this.userInfo}) : super(key: key);

  @override
  _UserInfoState createState() => _UserInfoState();
}

class _UserInfoState extends State<UserInfo> {
  @override
  Widget build(BuildContext context) {
    return buildUserProfile(widget.userInfo);
  }

  buildUserProfile(User userInfo) {
    return SingleChildScrollView(child: Column(
        children: [
          SizedBox(height: 15,),
          Image.network(Utils.getAvatarUrl(userInfo)),
/*
          ListTile(
            title: Text('id'),
            subtitle: Text(userInfo.id),
          ),
*/
          ListTile(
            title: Text('User name'),
            subtitle: Text(userInfo.username == null ? '' : userInfo.username),
          ),
          ListTile(
            title: Text('Display name'),
            subtitle: Text(userInfo.name),
          ),
          ListTile(
            title: Text('email'),
            subtitle: userInfo.emails != null && userInfo.emails.first != null ? Text(userInfo.emails.first.address.toString()) : SizedBox(),
          ),
          Container(
              padding: EdgeInsets.only(top: 5),
              child: InkWell(
                  onTap: () { Navigator.pop(context, 'im.create'); },
                  child: Wrap(children: <Widget>[
                    Icon(Icons.chat_outlined),
                    Text('Direct Message'),
                  ],)
              )),
        ]));
  }
}
