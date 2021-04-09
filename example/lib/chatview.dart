import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
import 'package:rocket_chat_connector_flutter/models/response/message_new_response.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:rocket_chat_connector_flutter/web_socket/notification_type.dart';
import 'constants/constants.dart';

class ChatView extends StatefulWidget {
  final Stream<rocket_notification.Notification> notificationStream;
  final Authentication authRC;
  final Channel channel;

  ChatView({Key key, @required this.notificationStream, @required this.authRC, @required this.channel}) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  TextEditingController _teController = TextEditingController();
  int chatItemOffset = 0;
  final int chatItemCount = 20;

  List<Message> chatData = [];
  bool historyEnd = false;

  @override
  void initState() {
    widget.notificationStream.listen((event) {
      if (event.msg == NotificationType.CHANGED)
        setState(() {
          chatItemOffset = 0;
        });
    });
    super.initState();
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
              chatData.sort((a, b) {
                return b.ts.compareTo(a.ts);
              });
              debugPrint("msg count=" + channelMessages.length.toString());
              debugPrint("total msg count=" + chatData.length.toString());
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
                          bool joinMessage = message.t != null && message.t == 'uj';
                          //debugPrint("msg=" + index.toString() + message.toString());
                          String url = message.user.avatarUrl == null ?
                              serverUri.replace(path: '/avatar/${message.user.username}', query: 'format=png').toString() :
                              message.user.avatarUrl;
                          return Container(
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
                              child:
                                ListTile(
                                  dense: true,
                                  leading: Container(
                                      width: joinMessage ? 20 : 40,
                                      height: joinMessage ? 20 : 40,
                                      child: Image.network(url)
                                  ),
                                  title: Text(
                                    message.user.username + '(' + index.toString() +')',
                                    style: TextStyle(fontSize: 10, color: Colors.brown),
                                    textAlign: TextAlign.left,
                                  ),
                                  subtitle: Text(
                                    joinMessage ? message.user.username + ' joined' : message.msg,
                                    style: TextStyle(fontSize: 10, color: Colors.blueAccent),
                                  )
                                )
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
                      onTap: _postMessage,
                      child: Icon(Icons.send, color: Colors.blueAccent,),
                    ), // This trailing comma makes auto-formatting nicer for build methods.
                  ])
                  )
              ]),
            );
          } else
            return Container();
        }
    );
  }

  Future<void> _postMessage() async {
    if (_teController.text.isNotEmpty) {
      MessageService messageService = MessageService(rocketHttpService);
      MessageNew msg = MessageNew(channel: widget.channel.id, roomId: widget.channel.name, text: _teController.text);
      MessageNewResponse respMsg = await messageService.postMessage(msg, widget.authRC);
      _teController.text = '';
      setState(() {
        chatData.add(respMsg.message);
      });
    }
  }

  Future<ChannelMessages> _getChannelMessages(int count, int offset) {
    ChannelService channelService = ChannelService(rocketHttpService);
    ChannelHistoryFilter filter = ChannelHistoryFilter(widget.channel, count: count, offset: offset);
    Future<ChannelMessages> messages = channelService.history(filter, widget.authRC);
    return messages;
  }
}
