import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:superchat/database/chatdb.dart';
import 'utils/utils.dart';
import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:superchat/constants/constants.dart';
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
          future: Utils.getUserInfo(widget.authRC, userId: widget.user.id, foreRefresh: true),
          builder: (context, AsyncSnapshot<User> snapshot) {
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());
            User userInfo = snapshot.data;
            bool googleProfile = userInfo.services != null && userInfo.services['google'] != null;
            return Column(
                children: [
                  SizedBox(height: 15,),
                  Image.network(Utils.getAvatarUrl(userInfo)),
                  TextButton(
                    child: Text('Change Avatar'),
                    onPressed: () async {
                      if (kIsWeb) {
                        FilePickerResult result = await FilePicker.platform.pickFiles();
                        if (result != null) {
                          if (result.files.single.bytes != null) {
                            await getUserService().avatarImageUpload(widget.authRC, bytes: result.files.single.bytes, fileName: result.files.single.name);
                            Future.delayed(Duration(seconds: 1), () { setState(() {}); });
                          }
                        }
                      } else {
                        final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);
                        File file = File(pickedFile.path);
                        await getUserService().avatarImageUpload(widget.authRC, file: file);
                        Future.delayed(Duration(seconds: 1), () { setState(() {}); });
                      }
                    },
                  ),
                  ListTile(
                    title: Text('id'),
                    subtitle: Text(userInfo.id),
                  ),
                  ListTile(
                    title: Text('user name'),
                    subtitle: Text(userInfo.username == null ? '' : userInfo.username),
                  ),
                  ListTile(
                    title: Text('display name'),
                    subtitle: Text(userInfo.name),
                  ),
                  ListTile(
                    title: Text('email'),
                    subtitle: userInfo.emails.first != null ? Text(userInfo.emails.first.address.toString()) : SizedBox(),
                  ),
                  Container(
                    padding: EdgeInsets.only(top: 20),
                    child: InkWell(
                    onTap: () {logout(googleProfile, widget.authRC);},
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

}
