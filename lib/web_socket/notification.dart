// To parse this JSON data, do
//
//     final notification = notificationFromMap(jsonString);

import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/message_user.dart';

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
  List<dynamic>? notificationArgs;

  factory NotificationFields.fromMap(Map<String, dynamic> json) => NotificationFields(
    eventName: json["eventName"] == null ? null : json["eventName"],
    notificationArgs: json["args"] == null ? null : List<dynamic>.from(json["args"]),
  );

  Map<String, dynamic> toMap() => {
    "eventName": eventName == null ? null : eventName,
    "args": notificationArgs == null ? null : List<dynamic>.from(notificationArgs!.map((x) => x)),
  };
}

