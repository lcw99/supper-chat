// To parse this JSON data, do
//
//     final notification = notificationFromMap(jsonString);

import 'dart:convert';

Notification notificationFromMap(String str) => Notification.fromMap(json.decode(str));

String notificationToMap(Notification data) => json.encode(data.toMap());

class Notification {
  Notification({
    this.msg,
    this.collection,
    this.id,
    this.notificationFields,
  });

  String? msg;
  String? collection;
  String? id;
  NotificationFields? notificationFields;

  factory Notification.fromMap(Map<String, dynamic> json) => Notification(
    msg: json["msg"] == null ? null : json["msg"],
    collection: json["collection"] == null ? null : json["collection"],
    id: json["id"] == null ? null : json["id"],
    notificationFields: json["fields"] == null ? null : NotificationFields.fromMap(json["fields"]),
  );

  Map<String, dynamic> toMap() => {
    "msg": msg == null ? null : msg,
    "collection": collection == null ? null : collection,
    "id": id == null ? null : id,
    "fields": notificationFields == null ? null : notificationFields!.toMap(),
  };
}

class NotificationFields {
  NotificationFields({
    this.eventName,
    this.notificationArgs,
  });

  String? eventName;
  List<NotificationArg>? notificationArgs;

  factory NotificationFields.fromMap(Map<String, dynamic> json) => NotificationFields(
    eventName: json["eventName"] == null ? null : json["eventName"],
    notificationArgs: json["args"] == null ? null : List<NotificationArg>.from(json["args"].map((x) => NotificationArg.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "eventName": eventName == null ? null : eventName,
    "args": notificationArgs == null ? null : List<dynamic>.from(notificationArgs!.map((x) => x.toMap())),
  };
}

class NotificationArg {
  NotificationArg({
    this.title,
    this.text,
    this.notificationPayload,
  });

  String? title;
  String? text;
  NotificationPayload? notificationPayload;

  factory NotificationArg.fromMap(Map<String, dynamic> json) => NotificationArg(
    title: json["title"] == null ? null : json["title"],
    text: json["text"] == null ? null : json["text"],
    notificationPayload: json["payload"] == null ? null : NotificationPayload.fromMap(json["payload"]),
  );

  Map<String, dynamic> toMap() => {
    "title": title == null ? null : title,
    "text": text == null ? null : text,
    "payload": notificationPayload == null ? null : notificationPayload!.toMap(),
  };
}

class NotificationPayload {
  NotificationPayload({
    this.id,
    this.rid,
    this.notificationSender,
    this.type,
    this.name,
    this.notificationMessage,
  });

  String? id;
  String? rid;
  NotificationSender? notificationSender;
  String? type;
  String? name;
  NotificationMessage? notificationMessage;

  factory NotificationPayload.fromMap(Map<String, dynamic> json) => NotificationPayload(
    id: json["_id"] == null ? null : json["_id"],
    rid: json["rid"] == null ? null : json["rid"],
    notificationSender: json["sender"] == null ? null : NotificationSender.fromMap(json["sender"]),
    type: json["type"] == null ? null : json["type"],
    name: json["name"] == null ? null : json["name"],
    notificationMessage: json["message"] == null ? null : NotificationMessage.fromMap(json["message"]),
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "rid": rid == null ? null : rid,
    "sender": notificationSender == null ? null : notificationSender!.toMap(),
    "type": type == null ? null : type,
    "name": name == null ? null : name,
    "message": notificationMessage == null ? null : notificationMessage!.toMap(),
  };
}

class NotificationMessage {
  NotificationMessage({
    this.msg,
  });

  String? msg;

  factory NotificationMessage.fromMap(Map<String, dynamic> json) => NotificationMessage(
    msg: json["msg"] == null ? null : json["msg"],
  );

  Map<String, dynamic> toMap() => {
    "msg": msg == null ? null : msg,
  };
}

class NotificationSender {
  NotificationSender({
    this.id,
    this.username,
    this.name,
  });

  String? id;
  String? username;
  String? name;

  factory NotificationSender.fromMap(Map<String, dynamic> json) => NotificationSender(
    id: json["_id"] == null ? null : json["_id"],
    username: json["username"] == null ? null : json["username"],
    name: json["name"] == null ? null : json["name"],
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "username": username == null ? null : username,
    "name": name == null ? null : name,
  };
}
