import 'dart:developer';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/message_new_response.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:rocket_chat_connector_flutter/web_socket/notification_type.dart';
import 'package:superchat/input_file_desc.dart';
import 'constants/constants.dart';

import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;

class ChatView extends StatefulWidget {
  final Stream<rocket_notification.Notification> notificationStream;
  final Authentication authRC;
  final String channelId;

  ChatView({Key key, @required this.notificationStream, @required this.authRC, @required this.channelId}) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  TextEditingController _teController = TextEditingController();
  int chatItemOffset = 0;
  final int chatItemCount = 20;

  List<Message> chatData = [];
  bool historyEnd = false;
  final picker = ImagePicker();

  @override
  void initState() {
    widget.notificationStream.listen((event) {
      if (event.msg == NotificationType.CHANGED) {
        if (event.fields.args.length > 0 && event.fields.args[0].payload.rid == widget.channelId) {
          setState(() {
            chatItemOffset = 0;
          });
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _teController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getChannelMessages(chatItemCount, chatItemOffset),
        builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
          if (snapshot.hasData) {
            List<Message> channelMessages = snapshot.data.messages;
            if (channelMessages.length > 0) {
              for (Message m in channelMessages)
                if (!chatData.contains(m))
                  chatData.add(m);
              chatData.sort((a, b) { return b.ts.compareTo(a.ts); });
              debugPrint("msg count=" + channelMessages.length.toString());
              debugPrint("total msg count=" + chatData.length.toString());

              final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
              ChannelService channelService = ChannelService(rocketHttpService);
              channelService.markAsRead(widget.channelId, widget.authRC);
              debugPrint("----------- mark channel(${widget.channelId}) as read");
            } else {
              historyEnd = true;
            }
            return Expanded(
                child: Column(children: <Widget>[
                  NotificationListener<ScrollEndNotification>(
                    child: Flexible(child:
                      ListView.builder(
                        padding: EdgeInsets.all(0.0),
                        scrollDirection: Axis.vertical,
                        itemCount: chatData.length,
                        reverse: true,
                        shrinkWrap: true,
                        itemBuilder: (context, index) {
                          Message message = chatData[index];
                          return Container(
                              //decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                              child: _buildChatItem(message, index),
                          );
                        }
                    )),
                    onNotification: (notification) {
                      if (notification.metrics.atEdge) {
                        print("listview Scrollend" + notification.metrics.pixels.toString());
                        if (!historyEnd && notification.metrics.pixels != 0.0) { // bottom
                          setState(() {
                            chatItemOffset += chatItemCount;
                          });
                        }
                      }
                      return true;
                    },
                ),
                Container(
                  child:
                  Row(children: <Widget>[
                    Expanded(child:
                    Form(
                      child: TextFormField(
                        controller: _teController,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        decoration: InputDecoration(hintText: 'New message', contentPadding: EdgeInsets.all(10)),
                      ),
                    )),
                    InkWell(
                      onTap: _pickImage,
                      child: Icon(Icons.image, color: Colors.blueAccent, size: 40,),
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 10),
                        child:
                    InkWell(
                      onTap: _postMessage,
                      child: Icon(Icons.send, color: Colors.blueAccent, size: 40,),
                    )),
                  ])
                  )
              ]),
            );
          } else
            return Container();
        }
    );
  }

  _buildChatItem(Message message, int index) {
    //log("msg=" + index.toString() + message.toString());
    bool specialMessage = message.t != null;
    String url = message.user.avatarUrl == null ?
                    serverUri.replace(path: '/avatar/${message.user.username}', query: 'format=png').toString() :
                    message.user.avatarUrl;
    String userName = _getUserName(message);
    String newMessage = message.msg;
    switch (message.t) {
      case 'au': newMessage = '$userName added ${message.msg}'; break;
      case 'uj': newMessage = '$userName joined'; break;
      case 'room_changed_avatar': newMessage = '$userName change room avatar'; break;
      case 'room_changed_description': newMessage = '$userName change room description'; break;
      default: if (message.t != null ) newMessage = '$userName act ${message.t}'; break;
    }
    return ListTile(
      dense: true,
      leading: Container(
          alignment: Alignment.centerLeft,
          width: specialMessage ? 20 : 40,
          height: specialMessage ? 20 : 40,
          child: Image.network(url)
      ),
      title: Text(
        userName + '(' + index.toString() +')',
        style: TextStyle(fontSize: 10, color: Colors.brown),
        textAlign: TextAlign.left,
      ),
      subtitle: _buildMessage(message, userName, newMessage),
    );
  }
  _getUserName(Message message) {
    String userName = '';
    if (message.user.username != null)
      userName += ' ' + message.user.username;
    if (message.user.name != null)
      userName += ' ' + message.user.name;
    return userName;
  }

  _buildMessage(Message message, String userName, String newMessage) {
    if (message.attachments == null || message.attachments.length == 0) {
      return Text(
        newMessage,
        style: TextStyle(fontSize: 10, color: Colors.blueAccent),
      );
    } else {
      var attachments = message.attachments;
      return Container(
        height: 150,
        child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: attachments.length,
            itemExtent: 200,
            itemBuilder: (context, index) {
              var attachment = attachments[index];
              return Column(children: <Widget>[
                getImage(attachment.imageUrl),
                attachment.description != null ? Text(attachment.description) : Container(),
              ]);
            }
        ));
    }
  }

  Widget getImage(String imagePath) {
    Map<String, String> header = {
      'X-Auth-Token': widget.authRC.data.authToken,
      'X-User-Id': widget.authRC.data.userId
    };
    return Image.network(serverUri.replace(path: imagePath).toString(), headers: header, fit: BoxFit.fitHeight, height: 130,);
  }

  Future<void> _postMessage() async {
    if (_teController.text.isNotEmpty) {
      final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
      MessageService messageService = MessageService(rocketHttpService);
      MessageNew msg = MessageNew(roomId: widget.channelId, text: _teController.text);
      MessageNewResponse respMsg = await messageService.postMessage(msg, widget.authRC);
      _teController.text = '';
      setState(() {
        chatData.add(respMsg.message);
      });
    }
  }

  Future<void> _pickImage() async {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    MessageService messageService = MessageService(rocketHttpService);

    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);
      String desc= await Navigator.push(context, MaterialPageRoute(builder: (context) => InputFileDescription(file: file)));
      Message newMessage = await messageService.roomImageUpload(widget.channelId, widget.authRC, file, desc: desc);
      setState(() {
        chatData.add(newMessage);
      });
    } else {
      print('No image selected.');
    }
  }

  Future<ChannelMessages> _getChannelMessages(int count, int offset) {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    ChannelService channelService = ChannelService(rocketHttpService);
    ChannelHistoryFilter filter = ChannelHistoryFilter(roomId: widget.channelId, count: count, offset: offset);
    Future<ChannelMessages> messages = channelService.history(filter, widget.authRC);
    return messages;
  }
}
