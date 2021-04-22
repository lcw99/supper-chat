import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:superchat/constants/constants.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:rocket_chat_connector_flutter/models/filters/userid_Filter.dart';

class MyProfile extends StatefulWidget {
  final User user;
  final Authentication authRC;
  MyProfile(this.user, this.authRC);

  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  User userInfo;

  @override
  void initState() {
    super.initState();
    userInfo = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    String url = userInfo.avatarUrl == null ?
      serverUri.replace(path: '/avatar/${userInfo.username}', query: 'format=png').toString() :
      serverUri.replace(path: Uri.parse(userInfo.avatarUrl).path).toString();
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body: Column(
        children: [
          Image.network(url),
          InkWell(
            child: Text('Change Avatar'),
            onTap: () async {
              final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
              File file = File(pickedFile.path);
              final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
              await UserService(rocketHttpService).avatarImageUpload(widget.authRC, file);
              userInfo = await UserService(rocketHttpService).getUserInfo(UserIdFilter(userInfo.id), widget.authRC);
              setState(() {});
            },
          ),
          ListTile(
            title: Text('id'),
            subtitle: Text(userInfo.id),
          ),
          ListTile(
            title: Text('user name'),
            subtitle: Text(userInfo.username),
          ),
          ListTile(
            title: Text('display name'),
            subtitle: Text(userInfo.name),
          ),
          ListTile(
            title: Text('email'),
            subtitle: Text(userInfo.emails.toString()),
          ),
        ],
      )
    );
  }
}
