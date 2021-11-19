import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:superchat/flatform_depended/platform_depended.dart';
import 'package:universal_io/io.dart' as uio;

import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image/image.dart' as image_util;
import 'package:image_picker/image_picker.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:superchat/chathome.dart';
import 'package:superchat/main.dart';
import 'edit_room.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rc;
import 'package:rocket_chat_connector_flutter/models/constants/message_id.dart';

import 'constants/constants.dart';
import 'chatview.dart';
import 'utils/dialogs.dart';
import 'utils/utils.dart';

class RoomInfo extends StatefulWidget {
  final ChatHomeState chatHomeState;
  final User user;
  final Room room;
  const RoomInfo({Key key, this.chatHomeState, this.user, this.room}) : super(key: key);

  @override
  _RoomInfoState createState() => _RoomInfoState();
}

class _RoomInfoState extends State<RoomInfo> {
  PickedFile newAvatar;
  TextEditingController _tecRoomAnnouncement = TextEditingController();
  TextEditingController _tecInviteExpire = TextEditingController();
  TextEditingController _tecInviteUse = TextEditingController();
  TextEditingController _tecInviteLinkUrl = TextEditingController();

  @override
  void initState() {
    resultMessageController.stream.listen((event) {
      onEvent(event);
    });

    _tecInviteExpire.text = '0';
    _tecInviteUse.text = '0';
    super.initState();
  }

  onEvent(rc.Notification event) {
    if (event.id == updateRoomParamId) {
      String msg;
      if (event.result != null && event.result['result']) {
        msg = "Room updated.";
      } else {
        msg = "Room update error";
      }
      Utils.showToast(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        leadingWidth: 25,
        title: Utils.getRoomTitle(context, widget.room, widget.user),
    ),
    body: FutureBuilder<model.Room>(
      future: getRoom(widget.room.id),
      builder: (context, AsyncSnapshot<model.Room> snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return buildPage(context, snapshot.data);
        } else
          return Center(child: CircularProgressIndicator(),);
    }));
  }

  Future<model.Room> getRoom(String roomId) {
    return getChannelService().getRoomInfo(widget.chatHomeState.widget.authRC, roomId: roomId);
  }

  Widget buildPage(context, model.Room room) {
    _tecRoomAnnouncement.text = room.announcement;

    double imageWidth = MediaQuery.of(context).size.width;
    double imageHeight = imageWidth * 0.6;
    Widget avatar = Icon(Icons.no_photography_outlined, size: 100, color: Colors.blueAccent,);
    if (newAvatar != null) {
      avatar = pickedImage(newAvatar.path, imageHeight: imageHeight, imageWidth: imageWidth, cacheWidth: 800);
    } else if (room.avatarETag != null)
      avatar = Image.network(serverUri.replace(path: '/avatar/room/${room.id}').toString(),
        fit: BoxFit.contain,
        width: imageWidth,
        height: imageHeight,
        cacheWidth: 800,
      );

    bool roomOwner = room.u.id == widget.user.id;
    return SingleChildScrollView(child: Container(
        padding: EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              Container(height: imageHeight, width: imageWidth, alignment: Alignment.center, child: avatar),
              Container(height: imageHeight, width: imageWidth, alignment: Alignment.bottomRight, child:
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                  InkWell(
                    onTap: () async {
                      newAvatar = await ImagePicker().getImage(source: ImageSource.gallery);
                      setState(() {});
                    },
                    child: DecoratedIcon(Icons.edit_outlined, color: Colors.blueAccent, size: 40,
                        shadows: [BoxShadow(color: Colors.black45, offset: Offset(3, 3))],),
                  ),
                  newAvatar != null ? InkWell(
                    onTap: () async {
                      var image = image_util.decodeImage(await newAvatar.readAsBytes());
                      var smallImage = image_util.copyResize(image, width: 200);
                      String base64 = 'data:image/jpeg;base64,' + base64Encode(image_util.encodeJpg(smallImage));
                      widget.chatHomeState.updateRoom(widget.room.id, roomAvatar: base64);
                    },
                    child: DecoratedIcon(Icons.save_outlined, color: Colors.blueAccent, size: 40,
                        shadows: [BoxShadow(color: Colors.black45, offset: Offset(3, 3))],),
                  ) : SizedBox(),
                ])
              ),
            ]),
            TextFormField(
              readOnly: true,
              initialValue: room.name,
              decoration: InputDecoration(
                labelText: 'Room name',
                border: UnderlineInputBorder(),
              ),
            ),
            TextFormField(
              readOnly: true,
              initialValue: room.t == 'p' ? 'Private' : 'Public',
              decoration: InputDecoration(
                labelText: 'Room type',
                border: UnderlineInputBorder(),
              ),
            ),
            TextFormField(
              maxLines: null,
              readOnly: true,
              initialValue: room.description,
              decoration: InputDecoration(
                labelText: 'Room description',
                border: UnderlineInputBorder(),
              ),
            ),
            TextFormField(
              maxLines: null,
              readOnly: true,
              initialValue: room.topic,
              decoration: InputDecoration(
                labelText: 'Room topic',
                border: UnderlineInputBorder(),
              ),
            ),
            Row(children: [
              Expanded(child: TextFormField(
                controller: _tecRoomAnnouncement,
                maxLines: null,
                readOnly: !roomOwner,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: 'Room announcement',
                  border: UnderlineInputBorder(),
                ),
              )),
              roomOwner ?
              InkWell(
                onTap: () async {
                  if (_tecRoomAnnouncement.text.isNotEmpty) {
                    var ret = await widget.chatHomeState.roomAnnouncement(room, _tecRoomAnnouncement.text);
                    if (ret.success)
                      Utils.showToast('Announcement updated');
                    else
                      Utils.showToast('Announcement update error');
                  }
                },
                child: Icon(Icons.announcement, color: Colors.blueAccent,)) :
              SizedBox(),
            ],),
                buildInvitePanel(roomOwner, room),
            SizedBox(height: 10,),
            Row(children: [
              TextButton(
                  onPressed: () {
                    deleteRoom(context);
                  },
                  child: Container(child:
                  Text('Delete')
                  )
              ),
              TextButton(
                  onPressed: () {
                    editRoom(context, room);
                  },
                  child: Container(child:
                    Text('Edit')
                  )
              ),
            ])
          ])
    ));
  }

  Future<void> editRoom(context, room) async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) =>
        EditRoom(chatHomeState: widget.chatHomeState, user: widget.user, room: room,)));
    setState(() {});
  }

  void deleteRoom(context) async {
    var result = await showSimpleAlertDialog(context, 'Delete Room', 'Are you sure?', () {
      chatHomeStateKey.currentState.deleteRoom(widget.room.id);
      Navigator.pop(context, 'OK');
    }, onCancel: () {
      Navigator.pop(context);
    });
    if (result == 'OK')
      Navigator.pop(context, 'room deleted');
  }

  buildInvitePanel(roomOwner, room) {
    return StatefulBuilder(builder: (context, setState) {
      return Column(children: [
        roomOwner && room.t == 'c' ?
        Row(children: [
          Expanded(child: TextFormField(
            controller: _tecInviteExpire,
            keyboardType: TextInputType.number,
            maxLines: 1,
            decoration: InputDecoration(
              labelText: 'Invite Exp. days',
              helperText: '0 for no limits',
              border: UnderlineInputBorder(),
            ),
          )),
          Expanded(child: TextFormField(
            controller: _tecInviteUse,
            keyboardType: TextInputType.number,
            maxLines: 1,
            decoration: InputDecoration(
              labelText: 'No. of use',
              helperText: '0 for no limits',
              border: UnderlineInputBorder(),
            ),
          )),
          InkWell(
              onTap: () async {
                int inviteExpire = 0;
                int inviteUse = 0;
                if (_tecInviteExpire.text.isNotEmpty)
                  inviteExpire = int.parse(_tecInviteExpire.text);
                if (_tecInviteUse.text.isNotEmpty)
                  inviteUse = int.parse(_tecInviteUse.text);
                var ret = await getUserService().findOrCreateInvite(room.id, inviteExpire, inviteUse, widget.chatHomeState.getAuthentication());
                if (ret.success) {
                  setState(() {
                    String token = ret.url.split('%2F')[1];
                    _tecInviteLinkUrl.text = Uri.parse(ret.url).replace(path: '/chat/#/join', queryParameters: {'invite': token}).toString().replaceAll('%23', '#');
                  });
                }
              },
              child: Icon(Icons.build_outlined, color: Colors.blueAccent,)),
        ]) : SizedBox(),
        _tecInviteLinkUrl.text.isNotEmpty ?
        Row(children: [
          Expanded(child: TextFormField(
            maxLines: null,
            readOnly: true,
            controller: _tecInviteLinkUrl,
            decoration: InputDecoration(
              labelText: 'Invite link url',
              border: UnderlineInputBorder(),
            ),
          )),
          InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _tecInviteLinkUrl.text));
              },
              child: Icon(Icons.copy, color: Colors.blueAccent,)),
        ],) : SizedBox(),
      ],);
    });
  }
}
