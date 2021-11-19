// To parse this JSON data, do
//
//     final notificationPayload = notificationPayloadFromMap(jsonString);

import 'dart:convert';

class NotificationPayload {
  NotificationPayload({
    this.id,
    this.rid,
    this.sender,
    this.type,
    this.name,
    this.message,
  });

  String? id;
  String? rid;
  Sender? sender;
  String? type;
  String? name;
  Message? message;

  factory NotificationPayload.fromMap(Map<String, dynamic> json) => NotificationPayload(
    id: json["_id"],
    rid: json["rid"],
    sender: json["sender"] != null ? Sender.fromMap(json["sender"]) : null,
    type: json["type"],
    name: json["name"],
    message: json["message"] != null ? Message.fromMap(json["message"]) : null,
  );

  Map<String, dynamic> toMap() => {
    "_id": id,
    "rid": rid,
    "sender": sender!.toMap(),
    "type": type,
    "name": name,
    "message": message!.toMap(),
  };
}

class Message {
  Message({
    this.msg,
  });

  String? msg;

  factory Message.fromMap(Map<String, dynamic> json) => Message(
    msg: json["msg"] != null ? json["msg"] : null,
  );

  Map<String, dynamic> toMap() => {
    "msg": msg,
  };
}

class Sender {
  Sender({
    this.id,
    this.username,
    this.name,
  });

  String? id;
  String? username;
  String? name;

  factory Sender.fromMap(Map<String, dynamic> json) => Sender(
    id: json["_id"],
    username: json["username"],
    name: json["name"],
  );

  Map<String, dynamic> toMap() => {
    "_id": id,
    "username": username,
    "name": name,
  };
}
