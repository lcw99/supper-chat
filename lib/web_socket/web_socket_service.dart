import 'dart:async';
import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/authentication.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {

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

  void streamNotifyUserSubscribe(WebSocketChannel webSocketChannel, User user) {
    Map msg = {
      "msg": "sub",
      "id": user.id! + "subscription-id",
      "name": "stream-notify-user",
      "params": [user.id! + "/notification", false]
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

  void streamChannelMessagesPong(WebSocketChannel webSocketChannel) {
    Map msg = {
      "msg": "pong",
    };
    webSocketChannel.sink.add(jsonEncode(msg));
  }

  void streamRoomMessagesSubscribe(WebSocketChannel webSocketChannel, String rid) {
    Map msg = {
      "msg": "sub",
      "id": "${rid}subscription-id",
      "name": "stream-room-messages",
      "params": ["$rid", false]
    };
    var data = jsonEncode(msg);
    print('socket=$data');
    webSocketChannel.sink.add(data);
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
}

