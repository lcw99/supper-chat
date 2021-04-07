import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/channel_messages.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';

final String webSocketUrl = "wss://chat.smallet.co/websocket";

final String serverUrl = "https://chat.smallet.co";
final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(Uri.parse(serverUrl));

class ChatView extends StatefulWidget {
  final Authentication authRC;
  final Channel channel;

  ChatView({Key key, @required this.authRC, @required this.channel}) : super(key: key);

  @override
  _ChatViewState createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  int chattingCount = 20;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getChannelMessages(),
        builder: (context, AsyncSnapshot<ChannelMessages> snapshot) {
          if (snapshot.hasData) {
            List<Message> channelMessages = snapshot.data.messages;
            //channelMessages.sort((a, b) { return a.ts.compareTo(b.ts); });
            debugPrint("msg count=" + channelMessages.length.toString());
            return Expanded(
              child: NotificationListener<ScrollEndNotification>(
                child: ListView.builder(
                    padding: EdgeInsets.all(0.0),
                    itemExtent: 40,
                    scrollDirection: Axis.vertical,
                    itemCount: channelMessages.length,
                    reverse: true,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      Message message = channelMessages[index];
                      bool joinMessage = message.t != null && message.t == 'uj';
                      //debugPrint("msg=" + index.toString() + message.toString());
                      return Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.red)),
                          child:
                          Column(children: [
                            Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.yellow)),
                                alignment: Alignment.centerLeft,
                                child:
                                Text(
                                  message.user.username + '(' + index.toString() +')',
                                  style: TextStyle(fontSize: 10, color: Colors.brown),
                                  textAlign: TextAlign.left,
                                )),
                            Container(
                                decoration: BoxDecoration(border: Border.all(color: Colors.yellow)),
                                alignment: Alignment.centerLeft,
                                child:
                                Text(
                                  joinMessage ? message.user.username + ' joined' : message.msg,
                                  style: TextStyle(fontSize: 10, color: Colors.blueAccent),
                                ))
                          ])
                      );
                    }
                ),
                onNotification: (notification) {
                  print("listview Scrollend" + notification.metrics.pixels.toString());
                  if (notification.metrics.pixels != 0.0) { // bottom
                    setState(() {
                      chattingCount += 20;
                    });
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
    ChannelHistoryFilter filter = ChannelHistoryFilter(widget.channel, count: chattingCount);
    Future<ChannelMessages> messages = channelService.history(filter, widget.authRC);
    return messages;
  }
}
