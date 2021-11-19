import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:superchat/utils/utils.dart';

class UserInfoWithAction extends StatefulWidget {
  final User userInfo;
  final Widget actionChild;
  const UserInfoWithAction({Key key, this.userInfo, this.actionChild}) : super(key: key);

  @override
  _UserInfoWithActionState createState() => _UserInfoWithActionState();
}

class _UserInfoWithActionState extends State<UserInfoWithAction> {
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
              child: widget.actionChild,
          ),
        ]));
  }
}
