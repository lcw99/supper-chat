import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/response/response.dart';

import 'edit_room.dart';
import 'model/join_info.dart';
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
import 'package:rocket_chat_connector_flutter/models/room.dart' as RC;
import 'package:rocket_chat_connector_flutter/models/subscription.dart' as RC;
import 'package:rocket_chat_connector_flutter/models/room_update.dart';
import 'package:rocket_chat_connector_flutter/models/subscription.dart';
import 'package:rocket_chat_connector_flutter/models/subscription_update.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as RC;
import 'package:rocket_chat_connector_flutter/web_socket/web_socket_service.dart';
import 'package:ss_image_editor/common/data/tu_chong_source.dart';
import 'package:superchat/chatitemview.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rocket_chat_connector_flutter/models/constants/message_id.dart';

import 'package:rocket_chat_connector_flutter/services/channel_service.dart';
import 'constants/constants.dart';
import 'package:rocket_chat_connector_flutter/services/http_service.dart' as rocket_http_service;
import 'package:rocket_chat_connector_flutter/models/filters/updatesince_filter.dart';
import 'package:rocket_chat_connector_flutter/models/permission.dart';
import 'my_profile.dart';
import 'wigets/unread_counter.dart';

import 'chatview.dart';
import 'database/chatdb.dart' as db;
import 'main.dart';

class ChatHome extends StatefulWidget {
  ChatHome({Key key, @required this.joinInfo, @required this.user, @required this.authRC, this.payload}) : super(key: key);
  final JoinInfo joinInfo;
  final User user;
  final Authentication authRC;
  final String payload;

  @override
  ChatHomeState createState() => ChatHomeState();
}

//WebSocketChannel webSocketChannel;
WebSocketService webSocketService;
WebSocketService getWebsocketService() => webSocketService;

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
final StreamController<RC.Notification> resultMessageController = StreamController<RC.Notification>.broadcast();

class ChatHomeState extends State<ChatHome> with WidgetsBindingObserver {
  Map<String, List<String>> roleToPermissions = Map<String, List<String>>();

  int selectedPage = 0;
  int totalUnread = 0;
  RC.Room selectedRoom;
  JoinInfo joinInfo;

  bool firebaseInitialized = false;

  final StreamController<RC.Notification> notificationController = StreamController<RC.Notification>.broadcast();

  static bool bChatScreenOpen = false;

  StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile> _sharedFiles;
  String _sharedText;

  bool isWebSocketClosed() => webSocketService.socketClosed;

  Authentication getAuthentication() => widget.authRC;

  @override
  void initState() {
    super.initState();

    joinInfo = widget.joinInfo;
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

  void joinRoomRequest(String joinToken) {
    Utils.showToast(joinToken);
  }

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
    Future.delayed(Duration(seconds: 3), () => webSocketService.close());
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
      //log('event=$e');
      print('event=$e');
      RC.Notification event = RC.Notification.fromMap(json);
      if (event.msg == WebSocketService.connectedMessage){
        webSocketService.getPermissions();
        webSocketService.subscribeNotifyUser(widget.user);
        webSocketService.subscribeStreamNotifyLogged();
        webSocketService.sendUserPresence("online");
        if (bChatScreenOpen && selectedRoom != null)
          subscribeRoomEvent(selectedRoom.id);
        return;
      }
      if (event.msg == WebSocketService.networkErrorMessage){
        showNetworkAlertDialog();
        return;
      }
      print('collection=${event.collection}');
      String data = jsonEncode(event.toMap());
      if (event.msg == 'ping') {
        webSocketService.streamChannelMessagesPong();
      } else {
        if (event.msg == 'updated') {
        } else if (event.msg == 'result') {
          if (event.id == getPermissionsId)
            parsePermissions(event);
          else {
            try {
              resultMessageController.add(event);
            } catch (e) {
              print('resultMessageController.add error=$e');
            }
          }
          try {
            notificationController.add(event);
          } catch (e) {
            print('notificationController.add error=$e');
          }
        } else if (event.msg == 'changed') {
          notificationController.add(event);
          if (event.collection == 'stream-notify-user' && event.notificationFields != null) {
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
                RC.Subscription sub = RC.Subscription.fromMap(event.notificationFields.notificationArgs[1]);
                String info = jsonEncode(sub.toMap());
                await locator<db.ChatDatabase>().upsertSubscription(db.Subscription(sid: sub.id, info: info));
                if (this.mounted)
                  setState(() {});
              } else if (event.notificationFields.notificationArgs[0] == 'removed') {
                if (this.mounted)
                  setState(() {});
              }
            } else if (eventName.endsWith('/message')) {
              if (event.notificationFields.notificationArgs[0]['msg'] != null)
              Utils.showToast(event.notificationFields.notificationArgs[0]['msg']);
            } else {
              print('**************** unknown eventName=$eventName');
            }
          }
          else if (event.collection == 'stream-notify-logged' && event.notificationFields != null) {
            String eventName = event.notificationFields.eventName;
            if (eventName == 'updateAvatar') {
              setState(() {
              });
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
        Future.delayed(Duration.zero, () { showNetworkAlertDialog(); });
      }
    }, cancelOnError: false);
  }

  showNetworkAlertDialog() async {
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

  showJoinAlertDialog() async {
    String content;
    bool needJoinCode = false;
    TextEditingController _tecJoinCode = TextEditingController();
    String errorText;

    RC.Room joinRoom = await getUserService().useInviteToken(joinInfo.inviteToken, widget.authRC);
    RC.Room room = await getUserService().channelsJoin(joinRoom.rid, widget.authRC);   // rid is valid, no id in this case;
    if (room.id == null) {
      if (room.error != null && room.error.contains('Password')) {
        content = 'Room(${joinRoom.name}) need join code.';
        needJoinCode = true;
      } else
        content = 'Room(${joinRoom.name}) is not allowed to join';
    } else
      content =  'Join to ${room.name}?';
    var rid = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Join room'),
              content: Column(children: [
                Text(content),
                SizedBox(height: 15,),
                TextFormField(
                  autofocus: true,
                  controller: _tecJoinCode,
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  decoration: InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.only(left: 5),
                      helperText: 'Join code', errorText: errorText),
                ),
              ],),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text("OK"),
                  onPressed: () async {
                    if (needJoinCode) {
                      if (_tecJoinCode.text.isEmpty)
                        setState(() {
                          errorText = 'Join code required.';
                        });
                      else {
                        room = await getUserService().channelsJoin(joinRoom.rid,  widget.authRC, joinCode: _tecJoinCode.text);   // rid is valid, no id in this case;
                        if (room.error == null && room.id != null)
                          Navigator.pop(context, room.id);
                        else
                          setState(() {
                            errorText = 'Join code not matched.';
                          });
                      }
                    } else
                      Navigator.pop(context, room.id);
                  },
                ),
              ]
          );});
        }
    );
    joinInfo = null;
    print('dialog ret=$rid');
    if (rid != null) {
      setChannelById(rid);
    }
  }

  handleSharedData() {
    _sharedText = null;
    // For sharing images coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) {
          _sharedFiles = value;
          print("Shared(1)!!!:" + (_sharedFiles?.map((f)=> f.path)?.join(",") ?? ""));
          notificationController.add(RC.Notification(msg: 'request_close'));
        }, onError: (err) {
          print("getIntentDataStream error: $err");
        });

    // For sharing images coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) {
      _sharedFiles = value;
      notificationController.add(RC.Notification(msg: 'request_close'));
      print("Shared(2)!!!!:" + (_sharedFiles?.map((f)=> f.path)?.join(",") ?? ""));
    });

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription =
        ReceiveSharingIntent.getTextStream().listen((String value) {
          print('shared text!!!(1) = $value');
          _sharedText = value;
          notificationController.add(RC.Notification(msg: 'request_close'));
        }, onError: (err) {
          print("getLinkStream error: $err");
        });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.getInitialText().then((String value) {
      print('shared text!!!(2) = $value');
      _sharedText = value;
      notificationController.add(RC.Notification(msg: 'request_close'));
    });
  }


  @override
  Widget build(BuildContext context) {
    print('#######-------------------######### joinInfo=$joinInfo');
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
                await Navigator.push(context, MaterialPageRoute(builder: (context) => EditRoom(chatHomeState: this, user: widget.user)));
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

  Widget _buildPage() {
    debugPrint("_buildPage=" + selectedPage.toString());
    switch(selectedPage) {
      case 0:
        return buildMainScrollView(null, 'MY ROOMS', 'assets/images/nepal-2184940_1920.jpg');
        break;
      case 1:
        return buildMainScrollView('c', 'PUBLIC', 'assets/images/sunrise-1634197_1920.jpg');
        break;
      case 2:
        return buildMainScrollView('d', 'DIRECT', 'assets/images/mountains-1158269_1920.jpg');
        break;
    }
  }

  buildMainScrollView(String roomType, String title, String imagePath) {
    return CustomScrollView(
        slivers: <Widget>[
          buildSilverAppbar(title, imagePath),
          FutureBuilder<List<RC.Room>>(
            future: _getMyRoomList(roomType: roomType, titleText: title, imagePath: imagePath),
            builder: roomBuilder
          )
        ]
    );
  }

  Widget roomBuilder(context, AsyncSnapshot<List<RC.Room>> snapshot) {
    if (snapshot.hasData) {
      if (snapshot.connectionState == ConnectionState.done && joinInfo != null) {
        Future.delayed(Duration.zero, () {
          showJoinAlertDialog();
        });
      }
      return buildSilverList(snapshot.data);
    } else {
      return SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 1,)));
    }
  }

  buildSilverAppbar(titleText, imagePath) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      flexibleSpace: FlexibleSpaceBar(
          centerTitle: true,
          title: Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(titleText, style: TextStyle(fontFamily: 'Audiowide', fontSize: 15),),
            ]),
          background: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          )),
    );
  }

  buildSilverList(roomList) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        RC.Room room = roomList[index];
        String roomName = room.name;
        int unreadCount = 0;
        if (room.subscription != null && room.subscription.unread != null && room.subscription.unread > 0)
          unreadCount = room.subscription.unread;
        if (roomName == null) {
          if (room.t == 'd') {
            roomName = room.usernames.toString();
          }
        }

        Widget roomType;
        if (room.t == 'c')
          roomType = Icon(Icons.public, color: Colors.blueAccent, size: 17,);
        else if (room.t == 'p')
          roomType = Icon(Icons.lock, color: Colors.blueAccent, size: 17);
        else if (room.t == 'd')
          roomType = Icon(Icons.chat, color: Colors.blueAccent, size: 17);
        else
          roomType = Icon(Icons.device_unknown, color: Colors.yellow, size: 17);

        return ListTile(
          onTap: () {
            _setChannel(room);
          },
          leading: Container(
              child: Image.network(room.roomAvatarUrl, fit: BoxFit.contain,)),
          title: Row(children: [
            roomType,
            SizedBox(width: 3,),
            Text(roomName, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            room.u != null && room.u.id == widget.user.id ?
            Icon(Icons.perm_identity, size: 17, color: Colors.indigo) : SizedBox(),
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
    );
  }

  buildSubTitle(RC.Room room) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          //Text(room.id, style: TextStyle(color: Colors.grey)),
          room.description != null && room.description.isNotEmpty ? Text(room.description, style: TextStyle(color: Colors.blue)) : SizedBox(),
          room.topic != null && room.topic.isNotEmpty ? Text(room.topic, style: TextStyle(color: Colors.blue)) : SizedBox(),
          room.announcement != null && room.announcement.isNotEmpty ? Text(room.announcement, style: TextStyle(color: Colors.blue)) : SizedBox(),
          getLastMessage(room) != null ? Text(getLastMessage(room), maxLines: 2, overflow: TextOverflow.fade, style: TextStyle(color: Colors.orange)) : SizedBox(),
          room.subscription != null && room.subscription.blocked != null && room.subscription.blocked ? Text('blocked', style: TextStyle(color: Colors.red)) : SizedBox(),
        ]
    );
  }

  String getLastMessage(RC.Room room) {
    String lm;
    if (room.lastMessage != null && room.lastMessage.msg != null)
      lm = room.lastMessage.msg;
    if ((lm == null || lm.isEmpty) && room.lastMessage != null && room.lastMessage.attachments != null && room.lastMessage.attachments.length > 0)
      lm = room.lastMessage.attachments.first.title;
    if (lm != null)
      lm = lm.replaceAll(RegExp(r'\[ \]\(.*\)[\s]*'), '');
    return lm;
  }

  void _onBottomNaviTapped(int index) {
    debugPrint("_onBottomNaviTapped =" + index.toString());
    setState(() {
      selectedPage = index;
    });
  }

  setChannelById(String rid) async {
    print('**** setChannelById=$rid');
    db.Room dbRoom = await locator<db.ChatDatabase>().getRoom(rid);
    RC.Room room = RC.Room.fromMap(jsonDecode(dbRoom.info));
    _setChannel(room);
  }

  _setChannel(RC.Room room) async {
    print('**** setChannel=${room.id}');
    selectedRoom = room;
    bool refresh = false;
/*
    if (room.subscription != null && room.subscription.unread > 0) {
      clearUnreadOnDB(room);
      refresh = true;
    }
*/
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

    if (result != null) {
      print('!!!!! auto navigate to room = $result');
      Future.delayed(Duration(seconds: 1), () { setChannelById(result); });
    }

    if (refresh)
      setState(() {});
  }

  Future<List<RC.Room>> _getMyRoomList({String roomType, String titleText, String imagePath}) async {
    var lastUpdate = await locator<db.ChatDatabase>().getValueByKey(db.lastUpdateRoom);
    DateTime updateSince;
    if (lastUpdate != null)
      updateSince = DateTime.tryParse(lastUpdate.value);

    print('updateSince = $updateSince');

    ChannelService channelService = getChannelService();
    UpdatedSinceFilter filter = UpdatedSinceFilter(updateSince);
    RoomUpdate roomUpdate = await channelService.getRooms(widget.authRC, filter);
    List<RC.Room> updatedRoom = roomUpdate.update;
    print('updatedRoom.length = ${updatedRoom.length}');

    if (roomType == 'c') {
      List<RC.Room> allPublicRoom = (await channelService.getChannelList(widget.authRC)).channelList;
      print('allPublicRoom.length = ${allPublicRoom.length}');
      for (RC.Room r in allPublicRoom) {
        r.roomAvatarUrl = await Utils.getRoomAvatarUrl(r, widget.authRC);
      }
      allPublicRoom.sort((b, a) { return a.lm != null && b.lm != null ? a.lm.compareTo(b.lm) : a.updatedAt.compareTo(b.updatedAt); });
      return allPublicRoom;
    }

    SubscriptionUpdate subsUpdate = await channelService.getSubscriptions(widget.authRC, filter);
    print('updatedSubs.update.length=${subsUpdate.update.length}');
    print('updatedSubs.remove.length=${subsUpdate.remove.length}');

    if (subsUpdate.update.isNotEmpty) {
      print('subs updated');
      for (RC.Subscription ms in subsUpdate.update) {
        if (ms.blocked != null && ms.blocked)
          print('blocked!!! = ${ms.rid}');
        String info = jsonEncode(ms.toMap());
        await locator<db.ChatDatabase>().upsertSubscription(db.Subscription(sid: ms.id, info: info));
      }
    }

    if (subsUpdate.remove.isNotEmpty) {
      print('subs removed');
      for (RC.Subscription ms in subsUpdate.remove) {
        db.Subscription dbSub = await locator<db.ChatDatabase>().getSubscription(ms.id);
        if (dbSub != null) {
          RC.Subscription sub = RC.Subscription.fromMap(jsonDecode(dbSub.info));
          await locator<db.ChatDatabase>().deleteSubscription(ms.id);
          await locator<db.ChatDatabase>().deleteRoom(sub.rid);
        }
      }
    }

    if (updatedRoom.isNotEmpty) {
      print('room updated');
      for (RC.Room mr in updatedRoom) {
        RC.Subscription subscription = subsUpdate.update.firstWhere((e) => e.rid == mr.id, orElse: () => null);
        String info = jsonEncode(mr.toMap());
        String sid = subscription == null ? null : subscription.id;
        await locator<db.ChatDatabase>().upsertRoom(db.Room(rid: mr.id, sid: sid, info: info));
      }
    }

    List<RC.Room> removedRoom = roomUpdate.remove;
    print('removedRoom.length = ${removedRoom.length}');

    if (removedRoom.isNotEmpty) {
      print('room removed');
      for (RC.Room mr in removedRoom) {
        await locator<db.ChatDatabase>().deleteRoom(mr.id);
      }
    }

    await locator<db.ChatDatabase>().upsertKeyValue(db.KeyValue(key: db.lastUpdateRoom, value: DateTime.now().toIso8601String()));
    var dbRooms = await locator<db.ChatDatabase>().getAllRooms;
    print('dbRooms = ${dbRooms.length}');
    List<RC.Room> roomList = [];
    totalUnread = 0;
    for (db.Room dr in dbRooms) {
      RC.Room room = RC.Room.fromMap(jsonDecode(dr.info));
      if (dr.sid != null) {
        var dbSubscription = await locator<db.ChatDatabase>().getSubscription(dr.sid);
        room.subscription = RC.Subscription.fromMap(jsonDecode(dbSubscription.info));
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
    return roomList;
  }

  @override
  void dispose() {
    webSocketService.sendUserPresence("offline");
    print('_+_+_+_+_+_dispose disconnecting web socket');
    unsubscribeAndClose();
    if (_intentDataStreamSubscription != null)
      _intentDataStreamSubscription.cancel();
    WidgetsBinding.instance.removeObserver(this);
    if (notificationController != null)
      notificationController.close();
    if (resultMessageController != null)
      resultMessageController.close();
    super.dispose();
  }

  clearUnreadOnDB(RC.Room room) async {
    db.Room dr = await locator<db.ChatDatabase>().getRoom(room.id);
    RC.Room mr = RC.Room.fromMap(jsonDecode(dr.info));
    if (mr.subscription != null) {
      mr.subscription.unread = 0;
      String info = jsonEncode(mr.toMap());
      await locator<db.ChatDatabase>().upsertRoom(db.Room(rid: mr.id, info: info));
    }
  }

  deleteMessage(messageId) {
    webSocketService.deleteMessage(messageId);
  }

  editMessage(String roomId, String msgId, String text) {
    getUserService().chatUpdate(roomId, msgId, text, widget.authRC);
  }

  createRoom(String roomName, List<String> users, bool private) {
    webSocketService.createRoom(roomName, users, private);
  }

  updateRoom(String roomId, {String roomName, String roomDescription,
      String roomTopic, String roomType, String roomAvatar,
      bool readOnly, bool systemMessages, bool defaultRoom, String joinCode}) {
    webSocketService.updateRoom(roomId, roomName: roomName, roomDescription: roomDescription,
        roomTopic: roomTopic, roomType: roomType, roomAvatar: roomAvatar,
        readOnly: readOnly, systemMessages: systemMessages, defaultRoom: defaultRoom, joinCode: joinCode
    );
  }

  deleteRoom(String roomId) {
    webSocketService.eraseRoom(roomId);
  }

  Future<Response> roomAnnouncement(RC.Room room, String announcement) async {
    return await getChannelService().roomAnnouncement(room, announcement, widget.authRC);
  }

  void parsePermissions(RC.Notification event) {
    List<dynamic> jsonList = event.result;
    List<Permission> permissions = jsonList.map((x) => Permission.fromMap(x)).toList();
    for (Permission p in permissions) {
      for (String r in p.roles) {
        if (roleToPermissions[r] == null)
          roleToPermissions[r] = [];
        roleToPermissions[r].add(p.id);
      }
    }
    //print("@@ user roles count=${userRoles.length}");
  }

  List<String> getPermissionsForRoles(List<String> roles) {
    List<String> permissions = [];
    if (roles == null)
      return permissions;
    for (String r in roles) {
      for (String p in roleToPermissions[r])
        if (!permissions.contains(p))
          permissions.add(p);
    }
    return permissions;
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
}

