import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/new/message_new.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/services/message_service.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:rocket_chat_connector_flutter/web_socket/web_socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/models/response/channel_list_response.dart';
import 'package:rocket_chat_connector_flutter/models/constants/constants.dart';

import 'chatview.dart';

final String webSocketUrl = "wss://chat.smallet.co/websocket";

class ChatHome extends StatefulWidget {
  final String title;
  final User user;
  final Authentication authRC;

  ChatHome({Key key, @required this.title, @required this.user, @required this.authRC}) : super(key: key);

  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  TextEditingController _controller = TextEditingController();
  int _selectedPage = 0;

  Channel channel = Channel(id: "myChannelId");
  Room room = Room(id: "myRoomId");

  bool firebaseInitialized = false;

  WebSocketChannel webSocketChannel;
  WebSocketService webSocketService = WebSocketService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    webSocketChannel = webSocketService.connectToWebSocket(webSocketUrl, widget.authRC);
    webSocketService.streamNotifyUserSubscribe(webSocketChannel, widget.user);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Form(
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(labelText: 'Send a message'),
              ),
            ),
            StreamBuilder(
              stream: webSocketChannel.stream,
              builder: (context, snapshot) {
                print(snapshot.data);
                String message;
                if (snapshot.hasError) {
                  message = "websocket error!!";
                } else if (snapshot.hasData) {
                  message = rocket_notification.Notification.fromMap(jsonDecode(snapshot.data)).toString();
                  webSocketService.streamNotifyUserSubscribe(webSocketChannel, widget.user);
                }
                print(message);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0.0),
                  //child: Text(message != null ? message : ''),
                  child: Text(''),
                );
              },
            ),
            _buildPage(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _postMessage,
        tooltip: 'Send message',
        child: Icon(Icons.send),
      ), // This trailing comma makes auto-formatting nicer for build methods.
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Rooms',
            backgroundColor: Colors.red,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatting',
            backgroundColor: Colors.green,
          ),
        ],
        currentIndex: _selectedPage,
        selectedItemColor: Colors.amber[800],
        onTap: _onBottomNaviTapped,
      ),
    );
  }

  _buildPage() {
    debugPrint("_buildPage=" + _selectedPage.toString());
    switch(_selectedPage) {
      case 0:
        return FutureBuilder<ChannelListResponse>(
            future: _getChannelList(),
            builder: (context, AsyncSnapshot<ChannelListResponse> snapshot) {
              if (snapshot.hasData) {
                ChannelListResponse r = snapshot.data;
                return Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: r.channelList.length,
                    itemBuilder: (context, index)  {
                      return ListTile(
                        onTap: () { _setChannel(index, r.channelList[index]); },
                        title: Text(r.channelList[index].name, style: TextStyle(color: Colors.black45)),
                        subtitle: Text(r.channelList[index].id, style: TextStyle(color: Colors.blue)),
                        leading: Container(
                          width: 40,
                          height: 40,
                          child: r.channelList[index].avatarETag != null ?
                            Image.network(serverUri.replace(path: '/avatar/room/${r.channelList[index].id}').toString()) :
                            const Icon(Icons.group)),
                        dense: true,
                        selected: channel.id == r.channelList[index].id,
                      );
                    },
                  ),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            });
        break;
      case 1:
        return ChatView(authRC: widget.authRC, channel: channel);
        break;
    }
  }

  void _onBottomNaviTapped(int index) {
    debugPrint("_onBottomNaviTapped =" + index.toString());
    setState(() {
      _selectedPage = index;
    });
  }

  _setChannel(int _index, Channel _channel) {
    setState(() {
      channel = _channel;
      _selectedPage = 1;
    });
    debugPrint("channel name=" + channel.name);
  }

  _getChannelList() {
    ChannelService channelService = ChannelService(rocketHttpService);
    Future<ChannelListResponse> respChannelList = channelService.list(widget.authRC);
    return respChannelList;
  }

  void _postMessage() {
    if (_controller.text.isNotEmpty) {
      MessageService messageService = MessageService(rocketHttpService);
      MessageNew msg = MessageNew(channel: channel.id, roomId: channel.name, text: _controller.text);
      messageService.postMessage(msg, widget.authRC);
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      webSocketService.sendMessageOnChannel(_controller.text, webSocketChannel, channel);
      webSocketService.sendMessageOnRoom(_controller.text, webSocketChannel, room);
    }
  }

  @override
  void dispose() {
    webSocketChannel.sink.close();
    super.dispose();
  }
}
