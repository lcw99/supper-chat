import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'utils/utils.dart';
import 'package:universal_io/io.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:oktoast/oktoast.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/response/channel_list_response.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart' as model;
import 'package:rocket_chat_connector_flutter/models/subscription.dart' as model;
import 'package:rocket_chat_connector_flutter/models/room_update.dart';
import 'package:rocket_chat_connector_flutter/models/subscription.dart';
import 'package:rocket_chat_connector_flutter/models/subscription_update.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;
import 'package:rocket_chat_connector_flutter/web_socket/web_socket_service.dart';
import 'package:ss_image_editor/common/data/tu_chong_source.dart';
import 'package:superchat/chatitemview.dart';
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
import 'update_room.dart';

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

//WebSocketChannel webSocketChannel;
WebSocketService webSocketService;

subscribeRoomEvent(String roomId) {
  webSocketService.subscribeRoomMessages(roomId);
  webSocketService.subscribeStreamNotifyRoom(roomId);
}

unsubscribeRoomEvent(String roomId) {
  try {
    webSocketService.unsubscribeRoomMessages(roomId);
    webSocketService.unsubscribeStreamNotifyRoom(roomId);
  } catch (ex) {
    print(ex.toString());
  }
}

AppLifecycleState appState = AppLifecycleState.resumed;
final StreamController<rocket_notification.Notification> resultMessageController = StreamController<rocket_notification.Notification>.broadcast();

class ChatHomeState extends State<ChatHome> with WidgetsBindingObserver {
  int selectedPage = 0;
  int totalUnread = 0;
  model.Room selectedRoom;

  bool firebaseInitialized = false;

  final StreamController<rocket_notification.Notification> notificationController = StreamController<rocket_notification.Notification>.broadcast();

  static bool bChatScreenOpen = false;

  StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles;
  String _sharedText;

  bool isWebSocketClosed() => webSocketService.socketClosed;

  void subscribeAndConnect() {
    print('_+_+_+_+_+_ connecting web socket');
    attachWebSocketHandler();
    webSocketService.connect();
  }

  Future<void> unsubscribeAndClose() async {
    print('_+_+_+_+_+_ disconnecting web socket');
    webSocketService.sendUserPresence("offline");
    if (bChatScreenOpen && selectedRoom != null)
      unsubscribeRoomEvent(selectedRoom.id);
    webSocketService.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('+++++====ChatHome state=$state');
    appState = state;
    if (state == AppLifecycleState.resumed) {
      subscribeAndConnect();
    } else if (state == AppLifecycleState.paused) {
      unsubscribeAndClose();
    }
  }

  StreamSubscription subscriptionWebSocketStream;
  attachWebSocketHandler() {
    if (subscriptionWebSocketStream != null)
      return;
    subscriptionWebSocketStream = webSocketService.getStreamController().stream.listen((e) async {
      var json = jsonDecode(e);
      print('event=$e');
      rocket_notification.Notification event = rocket_notification.Notification.fromMap(json);
      if (event.msg == WebSocketService.connectedMessage){
        webSocketService.subscribeNotifyUser(widget.user);
        webSocketService.subscribeStreamNotifyLogged();
        webSocketService.sendUserPresence("online");
        if (bChatScreenOpen && selectedRoom != null)
          subscribeRoomEvent(selectedRoom.id);
        return;
      }
      if (event.msg == WebSocketService.networkErrorMessage){
        showAlertDialog();
        return;
      }
      print('collection=${event.collection}');
      String data = jsonEncode(event.toMap());
      if (event.msg == 'ping') {
        webSocketService.streamChannelMessagesPong();
      } else {
        if (event.msg == 'updated') {
        } else if (event.msg == 'result') {
          if (event.id == '85' || event.id == '89' || event.id == '16') {  // 85: createChannel, 89: createPrivateGroup, 16: update room
            resultMessageController.add(event);
          }
        } else if (event.msg == 'changed') {
          notificationController.add(event);
          if (event.collection == 'stream-notify-user' &&event.notificationFields != null) {
            String eventName = event.notificationFields.eventName;
            if (eventName.endsWith('notification')) {
              if (event.notificationFields.notificationArgs != null &&
                  event.notificationFields.notificationArgs.length > 0) {
                var arg = event.notificationFields.notificationArgs[0];
                var payload = arg['payload'] != null ? jsonEncode(arg['payload']) : null;
                if (payload != null && !(bChatScreenOpen && selectedRoom != null && selectedRoom.id == arg['payload']['rid'])) {
                  RemoteMessage message = RemoteMessage(data: {'title': arg['title'], 'message': arg['text'], 'ejson': payload});
                  if (!kIsWeb)
                    androidNotification(message);
                }
              }
            } else if (eventName.endsWith('rooms-changed')) {
              print('!!!!! rooms-changed');
              if (this.mounted)
                setState(() {});
            } else if (eventName.endsWith('subscriptions-changed')) {
              print('!!!!! subscriptions-changed');
              if (event.notificationFields.notificationArgs[0] == 'updated') {
                model.Subscription sub = model.Subscription.fromMap(event.notificationFields.notificationArgs[1]);
                String info = jsonEncode(sub.toMap());
                await locator<db.ChatDatabase>().upsertSubscription(db.Subscription(sid: sub.id, info: info));
                if (this.mounted)
                  setState(() {});
              } else if (event.notificationFields.notificationArgs[0] == 'removed') {
                if (this.mounted)
                  setState(() {});
              }
            } else {
              print('**************** unknown eventName=$eventName');
            }
          }
        }
      }
    },
    onError: (Object error) {
      Logger().e('!#!#!#!#!#!#!# Socket onError!!!!!', error);
    },
    onDone: () {
      print('!#!#!#!#!#!#!# Socket onDone!!!!! = ${webSocketService.webSocketChannel.closeCode}, appState=$appState');
      if (appState == AppLifecycleState.resumed) {
        Logger().e('!#!#!#!#!#!#!# huh... network dead appState=$appState');
        Future.delayed(Duration.zero, () { showAlertDialog(); });
      }
    }, cancelOnError: false);
  }

  showAlertDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Network error'),
              content: Text('Retry to connect?'),
              actions: [
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    subscribeAndConnect();
                    Navigator.pop(context);
                  },
                ),
              ]
          );
        }
    );
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
    webSocketService = WebSocketService(url: webSocketUrl, authentication: widget.authRC);
    subscribeAndConnect();

    WidgetsBinding.instance.addObserver(this);

    if (!kIsWeb)
      handleSharedData();

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
            ListTile(
              title: Text('Create Room'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(context, MaterialPageRoute(builder: (context) => UpdateRoom(chatHomeState: this, user: widget.user)));
              },
            ),
            ListTile(
              title: Text('Delete Local Data'),
              onTap: deleteAllTables,
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
            icon: Icon(Icons.wb_sunny_outlined),
            label: 'Public',
            backgroundColor: Colors.green,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Direct',
            backgroundColor: Colors.green,
          ),
        ],
        currentIndex: selectedPage,
        selectedItemColor: Colors.amber[800],
        onTap: _onBottomNaviTapped,
      ),
    );
  }

  void deleteAllTables() async {
    var result = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text('Delete Local Data'),
              content: Text('Are you sure?'),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text("OK"),
                  onPressed: () {
                    locator<db.ChatDatabase>().deleteAllTables();
                    Navigator.pop(context, 'OK');
                  },
                ),
              ]
          );
        }
    );
    if (result == 'OK') {
      googleSignIn.signOut();
      navGlobalKey.currentState.pushAndRemoveUntil(MaterialPageRoute(builder: (context) => LoginHome()), (route) => false);
    }
  }

  _buildPage() {
    debugPrint("_buildPage=" + selectedPage.toString());
    switch(selectedPage) {
      case 0:
        return FutureBuilder<RoomSnapshotInfo>(
            future: _getMyRoomList(),
            builder: roomBuilder
        );
        break;
      case 1:
        return FutureBuilder<RoomSnapshotInfo>(
            future: _getPublicRoomList(),
            builder: roomBuilder,
        );
        break;
      case 2:
        return FutureBuilder<RoomSnapshotInfo>(
          future: _getMyRoomList(roomType: 'd', titleText: 'Direct', imagePath: 'assets/images/maldives-3220702_1920.jpg'),
          builder: roomBuilder,
        );
        break;
    }
  }

  Widget roomBuilder(context, AsyncSnapshot<RoomSnapshotInfo> snapshot) {
    if (snapshot.hasData) {
      List<model.Room> roomList = snapshot.data.roomList;
      return CustomScrollView(
        slivers: <Widget>[
        SliverAppBar(
          expandedHeight: 200.0,
          floating: false,
          pinned: true,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(snapshot.data.titleText, style: TextStyle(fontFamily: 'Audiowide', fontSize: 15),),
                  ]),
              background: Image.asset(
                snapshot.data.titleImagePath,
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
              leading: Container(
                  child: Image.network(room.roomAvatarUrl, fit: BoxFit.contain,)),
              title: Row(children: [
                room.t == 'p' ? Icon(Icons.lock, color: Colors.blueAccent, size: 17,) : Icon(Icons.public, color: Colors.blueAccent, size: 17),
                SizedBox(width: 3,),
                Text(roomName, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              ]),
              subtitle: buildSubTitle(room),
              trailing: UnreadCounter(unreadCount: unreadCount),
              dense: true,
              visualDensity: VisualDensity.compact,
              selectedTileColor: Colors.yellow.shade200,
              horizontalTitleGap: 15,
              selected: selectedRoom != null ? selectedRoom.id == room.id : false,
            );
          }, childCount: roomList.length,
          ),
        )
      ]);
    } else {
      return Container(color: Colors.white, child: Center(child: CircularProgressIndicator(strokeWidth: 1,)));
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
/*
    if (result != null) {
      print('!!!!! auto navigate to room = $result');
      Future.delayed(Duration(seconds: 1), () { setChannelById(result); });
    }
*/
    if (refresh)
      setState(() {});
  }

  ChannelService getChannelService() {
    final rocket_http_service.HttpService rocketHttpService = rocket_http_service.HttpService(serverUri);
    return ChannelService(rocketHttpService);
  }

  Future<RoomSnapshotInfo> _getPublicRoomList() async {
    ChannelListResponse rep = await getChannelService().getChannelList(widget.authRC);
    return RoomSnapshotInfo(rep.channelList, 'assets/images/sunrise-1634197_1920.jpg', 'PUBLIC ROOMS');
  }

  Future<RoomSnapshotInfo> _getMyRoomList({String roomType, String titleText, String imagePath}) async {
    var lastUpdate = await locator<db.ChatDatabase>().getValueByKey(db.lastUpdateRoom);
    DateTime updateSince;
    if (lastUpdate != null)
      updateSince = DateTime.tryParse(lastUpdate.value);

    print('updateSince = ${updateSince}');

    ChannelService channelService = getChannelService();
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
    }

    if (updatedRoom.isNotEmpty) {
      print('room updated');
      for (model.Room mr in updatedRoom) {
        model.Subscription subscription = subsUpdate.update.firstWhere((e) => e.rid == mr.id, orElse: () => null);
        String info = jsonEncode(mr.toMap());
        String sid = subscription == null ? null : subscription.id;
        await locator<db.ChatDatabase>().upsertRoom(db.Room(rid: mr.id, sid: sid, info: info));
      }
    }

    List<model.Room> removedRoom = roomUpdate.remove;
    print('removedRoom.length = ${removedRoom.length}');

    if (removedRoom.isNotEmpty) {
      print('room removed');
      for (model.Room mr in removedRoom) {
        await locator<db.ChatDatabase>().deleteRoom(mr.id);
      }
    }

    await locator<db.ChatDatabase>().upsertKeyValue(db.KeyValue(key: db.lastUpdateRoom, value: DateTime.now().toIso8601String()));
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
      if (roomType == null || (roomType != null && room.t == roomType)) {
        room.roomAvatarUrl = await Utils.getRoomAvatarUrl(room, widget.authRC);
        roomList.add(room);
      }
    }
    roomList.sort((b, a) { return a.lm != null && b.lm != null ? a.lm.compareTo(b.lm) : a.updatedAt.compareTo(b.updatedAt); });
    return RoomSnapshotInfo(roomList,
        imagePath != null ? imagePath : 'assets/images/nepal-2184940_1920.jpg',
        titleText != null ? titleText : 'MY ROOMS');
  }

  @override
  void dispose() {
    webSocketService.sendUserPresence("offline");
    print('_+_+_+_+_+_dispose disconnecting web socket');
    unsubscribeAndClose();
    _intentDataStreamSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    notificationController.close();
    resultMessageController.close();
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
          getLastMessage(room) != null ? Text(getLastMessage(room), maxLines: 2, overflow: TextOverflow.fade, style: TextStyle(color: Colors.orange)) : SizedBox(),
          room.subscription != null && room.subscription.blocked != null && room.subscription.blocked ? Text('blocked', style: TextStyle(color: Colors.red)) : SizedBox(),
        ]
    );
  }

  String getLastMessage(model.Room room) {
    String lm;
    if (room.lastMessage != null && room.lastMessage.msg != null)
      lm = room.lastMessage.msg;
    if ((lm == null || lm.isEmpty) && room.lastMessage != null && room.lastMessage.attachments != null && room.lastMessage.attachments.length > 0)
      lm = room.lastMessage.attachments.first.title;
    return lm;
  }

  deleteMessage(messageId) {
    webSocketService.deleteMessage(messageId);
  }

  editMessage(Message message) {
    webSocketService.updateMessage(message);
  }

  createRoom(String roomName, List<String> users, bool private) {
    webSocketService.createRoom(roomName, users, private);
  }

  updateRoom(String roomId, {String roomName, String roomDescription,
      String roomTopic, String roomType, String announcement, String roomAvatar}) {
    webSocketService.updateRoom(roomId, roomName: roomName, roomDescription: roomDescription,
        roomTopic: roomTopic, roomType: roomType, announcement: announcement, roomAvatar: roomAvatar);
  }

  deleteRoom(String roomId) {
    webSocketService.eraseRoom(roomId);
  }

}

class RoomSnapshotInfo {
  List<model.Room> roomList;
  String titleImagePath;
  String titleText;

  RoomSnapshotInfo(this.roomList, this.titleImagePath, this.titleText);
}

