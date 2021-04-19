import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {

  static int callcount = 0;

  WebSocketChannel connectToWebSocket(String url, Authentication authentication) {
    WebSocketChannel webSocketChannel = WebSocketChannel.connect(Uri.parse(url));
    _sendConnectRequest(webSocketChannel);
    _sendLoginRequest(webSocketChannel, authentication);

    return webSocketChannel;
  }

  void _sendConnectRequest(WebSocketChannel webSocketChannel) {
    Map msg = {
      "msg": "connect",
      "version": "1",
      "support": ["1", "pre2", "pre1"]
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void _sendLoginRequest(WebSocketChannel webSocketChannel, Authentication authentication) {
    Map msg = {
      "msg": "method",
      "method": "login",
      "id": "42",
      "params": [
        {"resume": authentication.data!.authToken}
      ]
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void subscribeNotifyUser(WebSocketChannel webSocketChannel, User user) {
    //subscribeNotifyUserEvent(webSocketChannel, user, 'message');
    //subscribeNotifyUserEvent(webSocketChannel, user, 'otr');
    //subscribeNotifyUserEvent(webSocketChannel, user, 'webrtc');
    subscribeNotifyUserEvent(webSocketChannel, user, 'notification');
    //subscribeNotifyUserEvent(webSocketChannel, user, 'rooms-changed');
    //subscribeNotifyUserEvent(webSocketChannel, user, 'subscriptions-changed');
    //subscribeNotifyUserEvent(webSocketChannel, user, 'uiInteraction');
    //subscribeNotifyUserEvent(webSocketChannel, user, 'e2ekeyRequest');
    //subscribeNotifyUserEvent(webSocketChannel, user, 'userData');
  }

  void subscribeNotifyUserEvent(WebSocketChannel webSocketChannel, User user, String event) {
    callcount++;
    Map msg = {
      "msg": "sub",
      "id": "stream-notify-user-$callcount",
      "name": "stream-notify-user",
      "params": ["${user.id}/$event", false]
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void subscribeRoomMessages(WebSocketChannel webSocketChannel, String rid) {
    callcount++;
    Map msg = {
      "msg": "sub",
      "id": "stream-room-messages-$callcount",
      "name": "stream-room-messages",
      "params": ["$rid", false]
    };
    var data = jsonEncode(msg);
    print('socket=$data');
    webSocketChannel.sink.add(data);
  }

  void streamChannelMessagesPong(WebSocketChannel webSocketChannel) {
    Map msg = {
      "msg": "pong",
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }


/*

  void streamNotifyUserSubscribe(WebSocketChannel webSocketChannel, User user) {
    Map msg = {
      "msg": "sub",
      "id": user.id! + "subscription-id",
      "name": "stream-notify-user",
      "params": [user.id! + "/notification", false]
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void streamNotifyLoggedSubscribe(WebSocketChannel webSocketChannel, String uid, String userName, int status) {
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

  void streamChannelMessagesUnsubscribe(WebSocketChannel webSocketChannel, Channel channel) {
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
      WebSocketChannel webSocketChannel, Room room) {
    Map msg = {
      "msg": "unsub",
      "id": room.id! + "subscription-id",
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void sendMessageOnChannel(
      String message, WebSocketChannel webSocketChannel, String channelId) {
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
      String message, WebSocketChannel webSocketChannel, Room room) {
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

  void sendUserPresence(WebSocketChannel webSocketChannel) {
    Map msg = {
      "msg": "method",
      "method": "UserPresence:setDefaultStatus",
      "id": "42",
      "params": ["online"]
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void streamNotifyRoomSubscribe(WebSocketChannel webSocketChannel, String rid) {
    Map msg = {
      "msg": "sub",
      "id": "${rid}subscription-id",
      "name": "stream-notify-room",
      "params": ["${rid}/event", false]
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }
*/
}

