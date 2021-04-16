import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/filters/channel_history_filter.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;
import 'package:rocket_chat_connector_flutter/models/room_update.dart';
import 'package:rocket_chat_connector_flutter/models/subscription.dart';
import 'package:rocket_chat_connector_flutter/models/subscription_update.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:rocket_chat_connector_flutter/web_socket/notification_type.dart';
import 'package:rocket_chat_connector_flutter/web_socket/web_socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'package:rocket_chat_connector_flutter/models/response/channel_list_response.dart';
import 'constants/constants.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/models/filters/updatesince_filter.dart';

import 'chatview.dart';
import 'database/chatdb.dart' as db;
import 'database/chatdb.dart';
import 'main.dart';

final String webSocketUrl = "wss://chat.smallet.co/websocket";

class ChatHome extends StatefulWidget {
  ChatHome({Key key, @required this.title, @required this.user, @required this.authRC, this.payload}) : super(key: key);
  final String title;
  final User user;
  final Authentication authRC;
  final String payload;

  @override
  _ChatHomeState createState() => _ChatHomeState();
}

class _ChatHomeState extends State<ChatHome> {
  int selectedPage = 0;

  model.Room selectedRoom;

  bool firebaseInitialized = false;

  WebSocketChannel webSocketChannel;
  WebSocketService webSocketService = WebSocketService();

  final StreamController<rocket_notification.Notification> notificationController = StreamController<rocket_notification.Notification>.broadcast();
  Stream<rocket_notification.Notification> notificationStream;

  @override
  void initState() {
    super.initState();

    notificationStream = notificationController.stream;
    webSocketChannel = webSocketService.connectToWebSocket(webSocketUrl, widget.authRC);
    webSocketService.streamNotifyUserSubscribe(webSocketChannel, widget.user);
    webSocketChannel.stream.listen((event) {
      rocket_notification.Notification notification = rocket_notification.Notification.fromMap(jsonDecode(event));
      String data = notification.toString();
      if (notification.msg == NotificationType.PING)
        webSocketService.streamChannelMessagesPong(webSocketChannel);
      else {
        print("***got noti= " + data);
        notificationController.add(notification);
      }
      onError() {}
      onDone() {}
    });

    print('**** payload= ${widget.payload}');
    if (widget.payload != null) {
      var json = jsonDecode(widget.payload);
      String _rid = json['rid'];
      if (_rid != null) {
        print('**** rid= $_rid');
        _setChannelById(_rid);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildPage(),
          ],
        ),
      ),
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
        currentIndex: selectedPage,
        selectedItemColor: Colors.amber[800],
        onTap: _onBottomNaviTapped,
      ),
    );
  }

  _buildPage() {
    debugPrint("_buildPage=" + selectedPage.toString());
    switch(selectedPage) {
      case 0:
        return FutureBuilder<List<model.Room>>(
            //future: _getChannelList(),
            future: _getMyRoomList(),
            builder: (context, AsyncSnapshot<List<model.Room>> snapshot) {
              if (snapshot.hasData) {
                List<model.Room> roomList = snapshot.data;
                return Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: roomList.length,
                    itemBuilder: (context, index)  {
                      model.Room room = roomList[index];
                      String roomName = room.name;
                      if (roomName == null) {
                        if (room.t == 'd') {
                          roomName = room.usernames.toString();
                        }
                      }
                      return ListTile(
                        onTap: () { _setChannel(room); },
                        title: Text(roomName, style: TextStyle(color: Colors.black)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(room.id, style: TextStyle(color: Colors.grey)),
                            room.description != null ? Text(room.description, style: TextStyle(color: Colors.blue)) : Container(),
                            room.topic != null ? Text(room.topic, style: TextStyle(color: Colors.blue)) : Container(),
                            room.announcement != null ? Text(room.announcement, style: TextStyle(color: Colors.blue)) : Container(),
                          ]
                        ),
                        leading: Container(
                          width: 80,
                          height: 80,
                          child: room.avatarETag != null ?
                            Image.network(serverUri.replace(path: '/avatar/room/${room.id}').toString(), fit: BoxFit.fitWidth,) :
                            const Icon(Icons.group)),
                        dense: true,
                        selected: selectedRoom != null ? selectedRoom.id == room.id : false,
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
        return ChatView(authRC: widget.authRC, room: selectedRoom, notificationStream: notificationStream,);
        //return Container();
        break;
    }
  }

  void _onBottomNaviTapped(int index) {
    debugPrint("_onBottomNaviTapped =" + index.toString());
    setState(() {
      selectedPage = index;
    });
  }

  _setChannelById(String rid) async {
    db.Room dbRoom = await locator<db.ChatDatabase>().getRoom(rid);
    model.Room room = model.Room.fromMap(jsonDecode(dbRoom.info));
    _setChannel(room);
  }

  _setChannel(model.Room room) {
    print('**** setChannel=${room.id}');
    setState(() {
      selectedRoom = room;
      selectedPage = 1;
    });
  }

  _getChannelList() async {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    ChannelService channelService = ChannelService(rocketHttpService);
    Future<ChannelListResponse> respChannelList = channelService.list(widget.authRC);
    return respChannelList;
  }

  Future<List<model.Room>> _getMyRoomList() async {
    var lastUpdate = await locator<db.ChatDatabase>().getValueByKey(db.lastUpdate);
    DateTime updateSince;
    if (lastUpdate != null)
      updateSince = DateTime.tryParse(lastUpdate.value);

    print('updateSince = ${updateSince}');

    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    ChannelService channelService = ChannelService(rocketHttpService);
    UpdatedSinceFilter filter = UpdatedSinceFilter(updateSince);
    RoomUpdate roomUpdate = await channelService.getRooms(widget.authRC, filter);
    //Subscription subs = await channelService.getSubscriptions(widget.authRC, filter);
    List<model.Room> updatedRoom = roomUpdate.update;
    print('updatedRoom.length = ${updatedRoom.length}');

    if (updatedRoom.isNotEmpty) {
      print('room updated');
      await locator<db.ChatDatabase>().upsertKeyValue(db.KeyValue(key: db.lastUpdate, value: DateTime.now().toIso8601String()));
      for (model.Room mr in updatedRoom) {
        String info = jsonEncode(mr.toMap());
        await locator<db.ChatDatabase>().upsertRoom(db.Room(rid: mr.id, info: info));
      }
    }

    var dbRooms = await locator<db.ChatDatabase>().getAllRooms;
    print('dbRooms = ${dbRooms.length}');
    List<model.Room> roomList = [];
    for (db.Room dr in dbRooms) {
      roomList.add(model.Room.fromMap(jsonDecode(dr.info)));
    }

    return roomList;
  }

  @override
  void dispose() {
    webSocketChannel.sink.close();
    super.dispose();
  }
}
