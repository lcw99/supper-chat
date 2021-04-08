import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/models/constants/constants.dart';

final String webSocketUrl = "wss://chat.smallet.co/websocket";

class ChatView extends StatefulWidget {
  final Authentication authRC;
  final Channel channel;

  ChatView({Key key, @required this.authRC, @required this.channel}) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  int chatItemOffset = 0;
  final int chatItemCount = 20;

  List<Message> chatData = [];
  bool historyEnd = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getChannelMessages(),
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
              child: NotificationListener<ScrollEndNotification>(
                child: ListView.builder(
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
                      bool grp = message.groupable != null ? message.groupable : false;
                      return Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.red)),
                          child:
                            ListTile(
                              dense: true,
                              leading: grp ? Container() : Container(
                                  width: 40,
                                  height: 40,
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
                ),
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
            );
          } else
            return Container();
        }
    );
  }

  _getChannelMessages() {
    ChannelService channelService = ChannelService(rocketHttpService);
    ChannelHistoryFilter filter = ChannelHistoryFilter(widget.channel, count: chatItemCount, offset: chatItemOffset);
    Future<ChannelMessages> messages = channelService.history(filter, widget.authRC);
    return messages;
  }
}
