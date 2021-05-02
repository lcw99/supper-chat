import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;
import 'package:rocket_chat_connector_flutter/models/subscription.dart' as model;
import 'package:rocket_chat_connector_flutter/models/room_update.dart';
import 'package:rocket_chat_connector_flutter/models/subscription.dart';
import 'package:rocket_chat_connector_flutter/models/subscription_update.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:rocket_chat_connector_flutter/web_socket/web_socket_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'constants/constants.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/models/filters/updatesince_filter.dart';
import 'my_profile.dart';
import 'wigets/unread_counter.dart';

import 'chatview.dart';
import 'database/chatdb.dart' as db;
import 'main.dart';

final String webSocketUrl = "wss://chat.smallet.co/websocket";

class ChatHome extends StatefulWidget {
  ChatHome({Key key, @required this.title, @required this.user, @required this.authRC, this.payload}) : super(key: key);
  final String title;
  final User user;
  final Authentication authRC;
  final String payload;

  @override
  ChatHomeState createState() => ChatHomeState();
}

WebSocketChannel webSocketChannel;
WebSocketService webSocketService = WebSocketService();

subscribeRoomEvent(String roomId) {
  webSocketService.subscribeRoomMessages(webSocketChannel, roomId);
  webSocketService.subscribeStreamNotifyRoom(webSocketChannel, roomId);
}

unsubscribeRoomEvent(String roomId) {
  try {
    webSocketService.unsubscribeRoomMessages(webSocketChannel, roomId);
    webSocketService.unsubscribeStreamNotifyRoom(webSocketChannel, roomId);
  } catch (ex) {
    print(ex.toString());
  }
}

class ChatHomeState extends State<ChatHome> with WidgetsBindingObserver {
  int selectedPage = 0;
  int totalUnread = 0;
  model.Room selectedRoom;

  bool firebaseInitialized = false;

  final StreamController<rocket_notification.Notification> notificationController = StreamController<rocket_notification.Notification>.broadcast();
  Stream<rocket_notification.Notification> notificationStream;

  static bool bChatScreenOpen = false;
  bool bDBUpdated = false;

  StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles;
  String _sharedText;

  AppLifecycleState appState = AppLifecycleState.resumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('+++++====ChatHome state=$state');
    appState = state;
    if (state == AppLifecycleState.resumed) {
      connectWebSocket();
      webSocketService.sendUserPresence(webSocketChannel, "online");
    } else {
      if (state == AppLifecycleState.paused) {
        webSocketService.sendUserPresence(webSocketChannel, "offline");
        webSocketChannel.sink.close();
      }
    }
  }

  connectWebSocket() {
    webSocketChannel = webSocketService.connectToWebSocket(webSocketUrl, widget.authRC);
    webSocketService.subscribeNotifyUser(webSocketChannel, widget.user);
    webSocketService.subscribeStreamNotifyLogged(webSocketChannel);
    webSocketChannel.stream.listen((event) async {
      var e = jsonDecode(event);
      print('****************event=${event}');
      rocket_notification.Notification notification = rocket_notification.Notification.fromMap(e);
      print('collection=${notification.collection}');
      String data = jsonEncode(notification.toMap());
      if (notification.msg == 'ping') {
        if (appState == AppLifecycleState.resumed)
          webSocketService.streamChannelMessagesPong(webSocketChannel);
      } else {
        //print("***got noti= " + data);
        if (notification.msg == 'changed') {
          notificationController.add(notification);

          if (notification.collection == 'stream-notify-user' &&notification.notificationFields != null) {
            String eventName = notification.notificationFields.eventName;
            if (eventName.endsWith('notification')) {
              if (notification.notificationFields.notificationArgs != null &&
                  notification.notificationFields.notificationArgs.length > 0) {
                var arg = notification.notificationFields.notificationArgs[0];
                var payload = arg['payload'] != null ? jsonEncode(arg['payload']) : null;
                if (payload != null && !(bChatScreenOpen && selectedRoom != null && selectedRoom.id == arg['payload']['rid'])) {
                  RemoteMessage message = RemoteMessage(data: {'title': arg['title'], 'message': arg['text'], 'ejson': payload});
                  androidNotification(message);
                }
              }
            } else if (eventName.endsWith('rooms-changed')) {
              print('!!!!! rooms-changed');
              setState(() {});
            } else if (eventName.endsWith('subscriptions-changed')) {
              print('!!!!! subscriptions-changed');
              if (notification.notificationFields.notificationArgs[0] == 'updated') {
                model.Subscription sub = model.Subscription.fromMap(notification.notificationFields.notificationArgs[1]);
                String info = jsonEncode(sub.toMap());
                await locator<db.ChatDatabase>().upsertSubscription(db.Subscription(sid: sub.id, info: info));
                bDBUpdated = true;
                setState(() {});
              }
            } else {
              print('**************** unknown eventName=$eventName');
            }
          }
        }
      }
      onError() {}
      onDone() {}
    });
  }

  handleSharedData() {
    _sharedText = null;
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
          _sharedFiles = value;
          print("Shared(1)!!!:" + (_sharedFiles?.map((f)=> f.path)?.join(",") ?? ""));
          notificationController.add(rocket_notification.Notification(msg: 'request_close'));
        }, onError: (err) {
          print("getIntentDataStream error: $err");
        });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      _sharedFiles = value;
      notificationController.add(rocket_notification.Notification(msg: 'request_close'));
      print("Shared(2)!!!!:" + (_sharedFiles?.map((f)=> f.path)?.join(",") ?? ""));
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
          print('shared text!!!(1) = $value');
          _sharedText = value;
          notificationController.add(rocket_notification.Notification(msg: 'request_close'));
        }, onError: (err) {
          print("getLinkStream error: $err");
        });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String value) {
      print('shared text!!!(2) = $value');
      _sharedText = value;
      notificationController.add(rocket_notification.Notification(msg: 'request_close'));
    });
  }


  @override
  void initState() {
    super.initState();
    bDBUpdated = false;

    WidgetsBinding.instance.addObserver(this);

    handleSharedData();

    notificationStream = notificationController.stream;
    connectWebSocket();

    print('**** payload= ${widget.payload}');
    if (widget.payload != null) {
      var json = jsonDecode(widget.payload);
      String _rid = json['rid'];
      if (_rid != null) {
        print('**** rid= $_rid');
        setChannelById(_rid);
      }
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Super Chat'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('My Profile'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (context) => MyProfile(widget.user, widget.authRC)));
              },
            ),
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


  List<model.Room> lastRoomList;
  _buildPage() {
    debugPrint("_buildPage=" + selectedPage.toString());
    switch(selectedPage) {
      case 0:
        return FutureBuilder<List<model.Room>>(
            future: _getMyRoomList(),
            builder: (context, AsyncSnapshot<List<model.Room>> snapshot) {
              if (snapshot.hasData) {
                List<model.Room> roomList = snapshot.data;
                lastRoomList = roomList;
                return CustomScrollView(slivers: <Widget>[
                  SliverAppBar(
                    expandedHeight: 200.0,
                    floating: false,
                    pinned: true,
                    systemOverlayStyle: SystemUiOverlayStyle.dark,
                    flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
/*
                          Text(widget.title, style:
                            TextStyle(fontFamily: "Billabong", fontSize: 30, shadows: <Shadow>[
                            Shadow(
                              offset: Offset(-3.0, 3.0),
                              blurRadius: 5.0,
                              color: Color.fromARGB(255, 0, 0, 0),
                            ),
                          ])),
                          Image.asset('assets/images/logotextonly.png', width: 150, fit: BoxFit.fitWidth, isAntiAlias: true),
                          SizedBox(width: 5,),
                          UnreadCounter(unreadCount: totalUnread),
*/
                        ]),
                        background: Image.asset(
                          'assets/images/hot-air-balloon-2411851.jpg',
                          fit: BoxFit.cover,
                        )),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      model.Room room = roomList[index];
                      String roomName = room.name;
                      int unreadCount = 0;
                      if (room.subscription != null && room.subscription.unread != null && room.subscription.unread > 0)
                        unreadCount = room.subscription.unread;
                      if (roomName == null) {
                        if (room.t == 'd') {
                          roomName = room.usernames.toString();
                        }
                      }
                      return ListTile(
                        onTap: () {
                          _setChannel(room);
                        },
                        title: Text(roomName, style: TextStyle(color: Colors.black)),
                        subtitle: buildSubTitle(room),
                        leading: Container(
                          width: 80,
                          height: 80,
                          child: room.avatarETag != null ?
                            Image.network(serverUri.replace(path: '/avatar/room/${room.id}').toString(), fit: BoxFit.fitWidth,) :
                            const Icon(Icons.group)),
                        trailing: UnreadCounter(unreadCount: unreadCount),
                        dense: true,
                        selected: selectedRoom != null ? selectedRoom.id == room.id : false,
                      );
                    }, childCount: roomList.length,
                  ),
                )]);
              } else {
                return Container(color: Colors.white, child: Center(child: CircularProgressIndicator(strokeWidth: 1,)));
              }
            });
        break;
      case 1:
        return Container();
        break;
    }
  }

  void _onBottomNaviTapped(int index) {
    debugPrint("_onBottomNaviTapped =" + index.toString());
    setState(() {
      selectedPage = index;
    });
  }

  setChannelById(String rid) async {
    db.Room dbRoom = await locator<db.ChatDatabase>().getRoom(rid);
    model.Room room = model.Room.fromMap(jsonDecode(dbRoom.info));
    _setChannel(room);
  }

  _setChannel(model.Room room) async {
    print('**** setChannel=${room.id}');
    selectedRoom = room;
    bool refresh = false;
    if (room.subscription != null && room.subscription.unread > 0) {
      clearUnreadOnDB(room);
      refresh = true;
    }
    var sharedObj;
    if (_sharedText != null) {
      sharedObj = _sharedText;
      _sharedText = null;
    } else if (_sharedFiles != null) {
      sharedObj = _sharedFiles;
      _sharedFiles = null;
    }
    bChatScreenOpen = true;
    final result = await Navigator.push(context, MaterialPageRoute(
        builder: (context) => ChatView(chatHomeState: this, authRC: widget.authRC, room: selectedRoom, notificationController: notificationController, me: widget.user, sharedObject: sharedObj)),
    );
    bChatScreenOpen = false;
    if (refresh)
      setState(() {});
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
    List<model.Room> updatedRoom = roomUpdate.update;
    print('updatedRoom.length = ${updatedRoom.length}');

    SubscriptionUpdate subsUpdate = await channelService.getSubscriptions(widget.authRC, filter);
    print('updatedSubs.update.length=${subsUpdate.update.length}');
    print('updatedSubs.remove.length=${subsUpdate.remove.length}');

    if (subsUpdate.update.isNotEmpty) {
      print('subs updated');
      for (model.Subscription ms in subsUpdate.update) {
        if (ms.blocked != null && ms.blocked)
          print('blocked!!! = ${ms.rid}');
        String info = jsonEncode(ms.toMap());
        await locator<db.ChatDatabase>().upsertSubscription(db.Subscription(sid: ms.id, info: info));
      }
      bDBUpdated = true;
    }

    if (subsUpdate.remove.isNotEmpty) {
      print('subs removed');
      for (model.Subscription ms in subsUpdate.remove) {
        db.Subscription dbSub = await locator<db.ChatDatabase>().getSubscription(ms.id);
        if (dbSub != null) {
          model.Subscription sub = model.Subscription.fromMap(jsonDecode(dbSub.info));
          await locator<db.ChatDatabase>().deleteSubscription(ms.id);
          await locator<db.ChatDatabase>().deleteRoom(sub.rid);
        }
      }
      bDBUpdated = true;
    }

    if (updatedRoom.isNotEmpty) {
      print('room updated');
      for (model.Room mr in updatedRoom) {
        model.Subscription subscription = subsUpdate.update.firstWhere((e) => e.rid == mr.id, orElse: () => null);
        String info = jsonEncode(mr.toMap());
        String sid = subscription == null ? null : subscription.id;
        await locator<db.ChatDatabase>().upsertRoom(db.Room(rid: mr.id, sid: sid, info: info));
      }
      bDBUpdated = true;
    }

    List<model.Room> removedRoom = roomUpdate.remove;
    print('removedRoom.length = ${removedRoom.length}');

    if (removedRoom.isNotEmpty) {
      print('room removed');
      for (model.Room mr in removedRoom) {
        await locator<db.ChatDatabase>().deleteRoom(mr.id);
      }
      bDBUpdated = true;
    }

    if (bDBUpdated || lastRoomList == null) {
      await locator<db.ChatDatabase>().upsertKeyValue(db.KeyValue(key: db.lastUpdate, value: DateTime.now().toIso8601String()));
      var dbRooms = await locator<db.ChatDatabase>().getAllRooms;
      print('dbRooms = ${dbRooms.length}');
      List<model.Room> roomList = [];
      totalUnread = 0;
      for (db.Room dr in dbRooms) {
        model.Room room = model.Room.fromMap(jsonDecode(dr.info));
        if (dr.sid != null) {
          var dbSubscription = await locator<db.ChatDatabase>().getSubscription(dr.sid);
          room.subscription = model.Subscription.fromMap(jsonDecode(dbSubscription.info));
          //print('room unread=${room.subscription.unread}');
          //print('room(${room.id}) subscription blocked=${room.subscription.blocked}');
          totalUnread += room.subscription.unread;
        }
        roomList.add(room);
      }
      bDBUpdated = false;
      return roomList;
    } else {
      return lastRoomList;
    }
  }

  @override
  void dispose() {
    webSocketService.sendUserPresence(webSocketChannel, "offline");
    webSocketChannel.sink.close();
    _intentDataStreamSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  clearUnreadOnDB(model.Room room) async {
    db.Room dr = await locator<db.ChatDatabase>().getRoom(room.id);
    model.Room mr = model.Room.fromMap(jsonDecode(dr.info));
    if (mr.subscription != null) {
      mr.subscription.unread = 0;
      String info = jsonEncode(mr.toMap());
      await locator<db.ChatDatabase>().upsertRoom(db.Room(rid: mr.id, info: info));
    }
  }

  buildSubTitle(model.Room room) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //Text(room.id, style: TextStyle(color: Colors.grey)),
          room.description != null && room.description.isNotEmpty ? Text(room.description, style: TextStyle(color: Colors.blue)) : SizedBox(),
          room.topic != null && room.topic.isNotEmpty ? Text(room.topic, style: TextStyle(color: Colors.blue)) : SizedBox(),
          room.announcement != null ? Text(room.announcement, style: TextStyle(color: Colors.blue)) : SizedBox(),
          room.lastMessage != null ? Text(room.lastMessage.msg, maxLines: 2, overflow: TextOverflow.fade, style: TextStyle(color: Colors.orange)) : SizedBox(),
          room.subscription.blocked != null && room.subscription.blocked ? Text('blocked', style: TextStyle(color: Colors.red)) : SizedBox(),
        ]
    );
  }

  deleteMessage(messageId) {
    webSocketService.deleteMessage(webSocketChannel, messageId);
  }

  editMessage(Message message) {
    webSocketService.updateMessage(webSocketChannel, message);
  }

}
