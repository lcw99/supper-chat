import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:superchat/chathome.dart';
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
  bool logoutStarted = false;
  User userInfo;

  TextEditingController _tecUsername = TextEditingController();
  TextEditingController _tecDisplayName = TextEditingController();
  TextEditingController _tecEmail = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.user.name)),
      body: userInfo != null ? buildMyProfile() :
        FutureBuilder<User>(
          future: Utils.getUserInfo(widget.authRC, userId: widget.user.id, forceRefresh: true),
          builder: (context, AsyncSnapshot<User> snapshot) {
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());
            userInfo = snapshot.data;
            _tecUsername.text = userInfo.username;
            _tecDisplayName.text = userInfo.name;
            _tecEmail.text = userInfo.emails.first.address;
            return buildMyProfile();
          })
    );
  }

  buildMyProfile() {
    double avatarWidth = MediaQuery.of(context).size.width * .7;
    return SingleChildScrollView(child: Container(
      padding: EdgeInsets.only(top: 5, left: 30, right: 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15,),
        Stack(children: [
          Image.network(Utils.getAvatarUrl(userInfo), width: avatarWidth, height: avatarWidth * 0.7, fit: BoxFit.contain,),
          Container(alignment: Alignment.bottomRight, width: avatarWidth, height: avatarWidth * 0.7,  child:
            InkWell(
            child: Icon(Icons.edit_outlined, color: Colors.blueAccent),
            onTap: () async {
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
          )
        ]),
/*
        SizedBox(height: 10,),
        TextFormField(
          autofocus: true,
          readOnly: true,
          keyboardType: TextInputType.text,
          maxLines: 1,
          initialValue: userInfo.id,
          decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
            helperText: 'id', ),
        ),
*/
        SizedBox(height: 15,),
        TextFormField(
          autofocus: false,
          controller: _tecUsername,
          keyboardType: TextInputType.text,
          maxLines: 1,
          decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
            helperText: 'User name', ),
        ),
        SizedBox(height: 15,),
        TextFormField(
          autofocus: false,
          controller: _tecDisplayName,
          keyboardType: TextInputType.text,
          maxLines: 1,
          decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
            helperText: 'Display name', ),
        ),
        SizedBox(height: 15,),
        TextFormField(
          readOnly: true,
          controller: _tecEmail,
          keyboardType: TextInputType.text,
          maxLines: 1,
          decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
            helperText: 'email', ),
        ),
        Container(
            padding: EdgeInsets.only(top: 20),
            child: InkWell(
                onTap: () async {
                  String newUsername = userInfo.username != _tecUsername.text.trim() ? _tecUsername.text.trim() : null;
                  String newDisplayName = userInfo.name != _tecDisplayName.text.trim() ? _tecDisplayName.text.trim() : null;
                  String newEmail = userInfo.emails.first.address != _tecEmail.text.trim() ? _tecEmail.text.trim() : null;
                  var resp = await getUserService().updateOwnBasicInfo(widget.authRC,
                      username: newUsername, name: newDisplayName, email: newEmail);
                  if (resp.success) {
                    Utils.showToast('User updated successfully.');
                    Navigator.pop(context);
                  } else
                    Utils.showToast('User update error.');
                },
                child: Wrap(children: <Widget>[
                  Icon(Icons.edit_outlined, color: Colors.blueAccent,),
                  Text('Update', style: TextStyle(color: Colors.blueAccent),),
                ],)
            )),
        Container(
            padding: EdgeInsets.only(top: 20),
            child: logoutStarted ? SizedBox() : InkWell(
                onTap: () {
                  logout(widget.authRC);
                  setState(() {
                    logoutStarted = true;
                  });
                },
                child: Wrap(children: <Widget>[
                  Icon(Icons.logout, color: Colors.blueAccent,),
                  Text('Logout', style: TextStyle(color: Colors.blueAccent),),
                ],)
            )),
      ],
    )));
  }

}
