import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:superchat/constants/constants.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/services/user_service.dart';
import 'package:rocket_chat_connector_flutter/models/filters/userid_filter.dart';
import 'package:superchat/main.dart';

class MyProfile extends StatefulWidget {
  final User user;
  final Authentication authRC;
  MyProfile(this.user, this.authRC);

  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Profile')),
      body:
        FutureBuilder<User>(
          future: _getUserInfo(),
          builder: (context, AsyncSnapshot<User> snapshot) {
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());
            User userInfo = snapshot.data;
            String url = userInfo.avatarUrl == null ?
            serverUri.replace(path: '/avatar/${userInfo.username}', query: 'format=png').toString() :
            serverUri.replace(path: Uri.parse(userInfo.avatarUrl).path).toString();
            bool googleProfile = userInfo.services != null && userInfo.services['google'] != null;
            return Column(
                children: [
                  Image.network(url),
                  googleProfile
                    ? Text('Google Profile')
                    : InkWell(
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
                  Container(
                    padding: EdgeInsets.only(top: 20),
                    child: InkWell(
                    onTap: () {_logout(googleProfile);},
                    child: Wrap(children: <Widget>[
                      Icon(Icons.logout),
                      Text('Logout'),
                    ],)
                  )),
                ],
              );
          })
    );
  }

  Future<User> _getUserInfo() async {
    return UserService(rocketHttpService).getUserInfo(UserIdFilter(widget.user.id), widget.authRC);
  }

  void _logout(googleProfile) {
    if (!googleProfile)
      Navigator.pop(context);
    googleSignIn.signOut();
    navGlobalKey.currentState.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginHome()), (route) => false);
  }
}
