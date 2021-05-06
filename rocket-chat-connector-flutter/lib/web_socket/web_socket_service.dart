import 'dart:async';
import 'dart:convert';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rocket_chat_connector_flutter/web_socket/notification.dart' as rocket_notification;

class WebSocketService {
  String? url;
  Authentication? authentication;
  bool socketClosed = true;

  int connectionCount = 0;
  int errorCount = 0;
  static final WebSocketService _singleton = WebSocketService._internal();
  WebSocketChannel? webSocketChannel;

  static const connectedMessage = '--connected--';

  static const networkErrorMessage = '--network-error--';

  WebSocketService._internal() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      Logger().i('network changed = ${result.toString()}');
    });
  }

  StreamController<String> streamController = new StreamController(sync: true);

  factory WebSocketService({String? url, Authentication? authentication}) {
    _singleton.url = url;
    _singleton.authentication = authentication;
    return _singleton;
  }

  StreamController getStreamController() => streamController;

  bool connect() {
    if (!socketClosed) {
      Logger().e("websocket connection alive, connection count=$connectionCount");
      return false;
    }
    connectionCount++;
    if (connectionCount > 1)
      Logger().e("****** Websocket connection count=$connectionCount *****");
    else
      Logger().i("****** Websocket connection count=$connectionCount *****");
    webSocketChannel = WebSocketChannel.connect(Uri.parse(url!));
    socketClosed = false;
    _sendConnectRequest();
    _sendLoginRequest(authentication!);
    streamController.add(jsonEncode(rocket_notification.Notification(msg: connectedMessage).toMap()));
    webSocketChannel!.stream.listen((event) {
      socketClosed = false;
      //print('ws event = $event');
      streamController.add(event);
    }, onDone: () {
      Logger().w("****** Websocket donDone connection count=$connectionCount *****");
      socketClosed = true;
      if (connectionCount > 0) {    // abnormal disconnection. retry to connect
        Logger().w('retry to connect web socket');
        Future.delayed(Duration(seconds: 3), () {
          connectionCount = 0;
          connect();
        });
      }
    }, onError: (e) {
      errorCount++;
      if (errorCount > 3) {
        errorCount = 0;
        connectionCount = 0;
        streamController.add(jsonEncode(rocket_notification.Notification(msg: networkErrorMessage).toMap()));
      }
      Logger().e("****** Websocket donError connection count=$connectionCount, error=$errorCount *****", e);
    });
    return true;
  }

  void close() {
    connectionCount--;
    Logger().i("****** Websocket connection count=$connectionCount *****");
    webSocketChannel!.sink.close(1010, 'by_me');
  }

  void _sendConnectRequest() {
    Map msg = {
      "msg": "connect",
      "version": "1",
      "support": ["1", "pre2", "pre1"]
    };
    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void _sendLoginRequest(Authentication authentication) {
    Map msg = {
      "msg": "method",
      "method": "login",
      "id": "42",
      "params": [
        {"resume": authentication.data!.authToken}
      ]
    };

    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void deleteMessage(String messageId) {
    Map msg = {
      "msg": "method",
      "method": "deleteMessage",
      "id": "42",
      "params": [
        { "_id": messageId }
      ]
    };

    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void updateMessage(Message message) {
    Map msg = {
      "msg": "method",
      "method": "updateMessage",
      "id": "42",
      "params": [ message.toMap() ]
    };

    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void subscribeNotifyUser(User user) {
    subscribeNotifyUserEvent(user, 'message');
    //subscribeNotifyUserEvent(user, 'otr');
    //subscribeNotifyUserEvent(user, 'webrtc');
    subscribeNotifyUserEvent(user, 'notification');
    subscribeNotifyUserEvent(user, 'rooms-changed');
    subscribeNotifyUserEvent(user, 'subscriptions-changed');
    //subscribeNotifyUserEvent(user, 'uiInteraction');
    //subscribeNotifyUserEvent(user, 'e2ekeyRequest');
    //subscribeNotifyUserEvent(user, 'userData');
  }

  void subscribeNotifyUserEvent(User user, String event) {
    Map msg = {
      "msg": "sub",
      "id": "stream-notify-user-$event",
      "name": "stream-notify-user",
      "params": ["${user.id}/$event", false]
    };

    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void subscribeRoomMessages(String rid) {
    Map msg = {
      "msg": "sub",
      "id": "stream-room-messages-$rid",
      "name": "stream-room-messages",
      "params": ["$rid", false]
    };
    var data = jsonEncode(msg);
    print('socket=$data');
    webSocketChannel!.sink.add(data);
  }

  void unsubscribeRoomMessages(String rid) {
    Map msg = {
      "msg": "unsub",
      "id": "stream-room-messages-$rid",
    };
    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void streamChannelMessagesPong() {
    Map msg = {
      "msg": "pong",
    };
    try {
      webSocketChannel!.sink.add(jsonEncode(msg));
    } catch (e) {}
  }

  void sendUserPresence(String status) {
    Map msg = {
      "msg": "method",
      "method": "UserPresence:setDefaultStatus",
      "id": "42",
      "params": [status]
    };
    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void sendUserTyping(String roomId, String userName, bool typing) {
    Map msg = {
      "msg": "method",
      "method": "stream-notify-room",
      "id": "42",
      "params": ["$roomId/typing", "$userName", typing]
    };
    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void subscribeStreamNotifyRoom(String rid) {
    subscribeStreamNotifyRoomEvent(rid, 'typing');
    subscribeStreamNotifyRoomEvent(rid, 'deleteMessage');
  }

  void subscribeStreamNotifyRoomEvent(String rid, String event) {
    Map msg = {
      "msg": "sub",
      "id": "stream-notify-room-$rid-$event",
      "name": "stream-notify-room",
      "params": ["$rid/$event", false]
    };

    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void unsubscribeStreamNotifyRoom(String rid) {
    unsubscribeStreamNotifyRoomEvent(rid, 'typing');
    unsubscribeStreamNotifyRoomEvent(rid, 'deleteMessage');
  }

  void unsubscribeStreamNotifyRoomEvent(String rid, String event) {
    Map msg = {
      "msg": "unsub",
      "id": "stream-notify-room-$rid-$event",
    };
    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void subscribeStreamNotifyLogged() {
    subscribeStreamNotifyLoggedEvent('Users:NameChanged');
    subscribeStreamNotifyLoggedEvent('updateAvatar');
    subscribeStreamNotifyLoggedEvent('updateEmojiCustom');
    subscribeStreamNotifyLoggedEvent('deleteEmojiCustom');
    subscribeStreamNotifyLoggedEvent('roles-change');
    subscribeStreamNotifyLoggedEvent('user-status');
  }

  void subscribeStreamNotifyLoggedEvent(String event) {
    Map msg = {
      "msg": "sub",
      "id": "stream-notify-logged-$event",
      "name": "stream-notify-logged",
      "params": ["$event", false]
    };
    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void createRoom(String roomName, List<String> users, bool private, { bool readOnly = false, bool broadcast = false }) {
    String method = 'createChannel';
    String id = "85";
    if (private) {
      method = 'createPrivateGroup';
      id = "89";
    }
    Map msg = {
      "msg": "method",
      "method": "$method",
      "id": "$id",
      "params": ["$roomName", [users.toString()], readOnly, {}, { "broadcast":broadcast, "encrypted":false }]
    };
    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void eraseRoom(String roomId) {
    Map msg = {
      "msg": "method",
      "method": "eraseRoom",
      "id": "92",
      "params": ["$roomId"]
    };
    webSocketChannel!.sink.add(jsonEncode(msg));
  }

  void updateRoom(String roomId, {String? roomName, String? roomDescription, String? roomTopic, String? roomType}) {
    if (roomName != null)
      updateRoomParam(roomId, "roomName", roomName);
    if (roomDescription != null)
      updateRoomParam(roomId, "roomDescription", roomDescription);
    if (roomTopic != null)
      updateRoomParam(roomId, "roomTopic", roomTopic);
    if (roomType != null)
      updateRoomParam(roomId, "roomType", roomType);
  }

  void updateRoomParam(String roomId, String setting, String? value) {
    Map msg = {
      "msg": "method",
      "method": "saveRoomSettings",
      "id": "16",
      "params": ["$roomId", "$setting", "$value"]
    };
    webSocketChannel!.sink.add(jsonEncode(msg));
  }


/*

  void streamNotifyLoggedSubscribe(String uid, String userName, int status) {
    Map msg = {
      "msg": "sub",
      "id": "${uid}subscription-id",
      "name": "stream-notify-logged",
      "fields": {
        "eventName": "user-status",
        "args": [["$uid", "$userName", status]] // 0 Offline 1 Online 2 Away 3 Busy
      }
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void streamChannelMessagesUnsubscribe(Channel channel) {
    Map msg = {
      "msg": "unsub",
      "id": channel.id! + "subscription-id",
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void streamRoomNotifyAll(WebSocketChannel webSocketChannel) {
    Map msg = {
      "msg": "sub",
      "id": "subscription-id-9999",
      "name": "stream-notify-all",
      "params": ["event", false]
    };
    var data = jsonEncode(msg);
    print('socket=$data');
    webSocketChannel.sink.add(data);
  }

  void streamRoomMessagesUnsubscribe(
      Room room) {
    Map msg = {
      "msg": "unsub",
      "id": room.id! + "subscription-id",
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void sendMessageOnChannel(
      String message, String channelId) {
    Map msg = {
      "msg": "method",
      "method": "sendMessage",
      "id": "42",
      "params": [
        {"rid": channelId, "msg": message}
      ]
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void sendMessageOnRoom(
      String message, Room room) {
    Map msg = {
      "msg": "method",
      "method": "sendMessage",
      "id": "42",
      "params": [
        {"rid": room.id, "msg": message}
      ]
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }


*/
}

