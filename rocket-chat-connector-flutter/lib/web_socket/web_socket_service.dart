import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/message.dart';
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

  void deleteMessage(WebSocketChannel webSocketChannel, String messageId) {
    Map msg = {
      "msg": "method",
      "method": "deleteMessage",
      "id": "42",
      "params": [
        { "_id": messageId }
      ]
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void updateMessage(WebSocketChannel webSocketChannel, Message message) {
    Map msg = {
      "msg": "method",
      "method": "updateMessage",
      "id": "42",
      "params": [ message.toMap() ]
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void subscribeNotifyUser(WebSocketChannel webSocketChannel, User user) {
    subscribeNotifyUserEvent(webSocketChannel, user, 'message');
    //subscribeNotifyUserEvent(webSocketChannel, user, 'otr');
    //subscribeNotifyUserEvent(webSocketChannel, user, 'webrtc');
    subscribeNotifyUserEvent(webSocketChannel, user, 'notification');
    subscribeNotifyUserEvent(webSocketChannel, user, 'rooms-changed');
    subscribeNotifyUserEvent(webSocketChannel, user, 'subscriptions-changed');
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
    Map msg = {
      "msg": "sub",
      "id": "stream-room-messages-$rid",
      "name": "stream-room-messages",
      "params": ["$rid", false]
    };
    var data = jsonEncode(msg);
    print('socket=$data');
    webSocketChannel.sink.add(data);
  }

  void unsubscribeRoomMessages(WebSocketChannel webSocketChannel, String rid) {
    Map msg = {
      "msg": "unsub",
      "id": "stream-room-messages-$rid",
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void streamChannelMessagesPong(WebSocketChannel webSocketChannel) {
    Map msg = {
      "msg": "pong",
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void sendUserPresence(WebSocketChannel webSocketChannel, String status) {
    Map msg = {
      "msg": "method",
      "method": "UserPresence:setDefaultStatus",
      "id": "42",
      "params": [status]
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void sendUserTyping(WebSocketChannel webSocketChannel, String roomId, String userName, bool typing) {
    Map msg = {
      "msg": "method",
      "method": "stream-notify-room",
      "id": "42",
      "params": ["$roomId/typing", "$userName", typing]
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void subscribeStreamNotifyRoom(WebSocketChannel webSocketChannel, String rid) {
    subscribeStreamNotifyRoomEvent(webSocketChannel, rid, 'typing');
    subscribeStreamNotifyRoomEvent(webSocketChannel, rid, 'deleteMessage');
  }

  void subscribeStreamNotifyRoomEvent(WebSocketChannel webSocketChannel, String rid, String event) {
    callcount++;
    Map msg = {
      "msg": "sub",
      "id": "stream-notify-room-$rid-$event",
      "name": "stream-notify-room",
      "params": ["$rid/$event", false]
    };

    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void unsubscribeStreamNotifyRoom(WebSocketChannel webSocketChannel, String rid) {
    unsubscribeStreamNotifyRoomEvent(webSocketChannel, rid, 'typing');
    unsubscribeStreamNotifyRoomEvent(webSocketChannel, rid, 'deleteMessage');
  }

  void unsubscribeStreamNotifyRoomEvent(WebSocketChannel webSocketChannel, String rid, String event) {
    Map msg = {
      "msg": "unsub",
      "id": "stream-notify-room-$rid-$event",
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void subscribeStreamNotifyLogged(WebSocketChannel webSocketChannel) {
    subscribeStreamNotifyLoggedEvent(webSocketChannel, 'Users:NameChanged');
    subscribeStreamNotifyLoggedEvent(webSocketChannel, 'updateAvatar');
    subscribeStreamNotifyLoggedEvent(webSocketChannel, 'updateEmojiCustom');
    subscribeStreamNotifyLoggedEvent(webSocketChannel, 'deleteEmojiCustom');
    subscribeStreamNotifyLoggedEvent(webSocketChannel, 'roles-change');
    subscribeStreamNotifyLoggedEvent(webSocketChannel, 'user-status');
  }

  void subscribeStreamNotifyLoggedEvent(WebSocketChannel webSocketChannel, String event) {
    Map msg = {
      "msg": "sub",
      "id": "stream-notify-logged-$event",
      "name": "stream-notify-logged",
      "params": ["$event", false]
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void createRoom(WebSocketChannel webSocketChannel, String roomName, List<String> users, bool private, { bool readOnly = false, bool broadcast = false }) {
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
    webSocketChannel.sink.add(jsonEncode(msg));
  }

/*

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


*/
}

