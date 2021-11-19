// To parse this JSON data, do
//
//     final notification = notificationFromMap(jsonString);

import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/message_user.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';

Notification notificationFromMap(String str) => Notification.fromMap(json.decode(str));

String notificationToMap(Notification data) => json.encode(data.toMap());

class Notification {
  Notification({
    this.msg,
    this.collection,
    this.id,
    this.notificationFields,
    this.error,
    this.result,
  });

  String? msg;
  String? collection;
  String? id;
  NotificationFields? notificationFields;
  Error? error;
  dynamic? result;

  factory Notification.fromMap(Map<String, dynamic> json) => Notification(
    msg: json["msg"] == null ? null : json["msg"],
    collection: json["collection"] == null ? null : json["collection"],
    id: json["id"] == null ? null : json["id"],
    notificationFields: json["fields"] == null ? null : NotificationFields.fromMap(json["fields"]),
    error: json["error"] == null ? null : Error.fromMap(json["error"]),
    result: json["result"] == null ? null : json["result"],
  );

  Map<String, dynamic> toMap() => {
    "msg": msg == null ? null : msg,
    "collection": collection == null ? null : collection,
    "id": id == null ? null : id,
    "fields": notificationFields == null ? null : notificationFields!.toMap(),
    "error": error == null ? null : error!.toMap(),
    "result": result == null ? null : result,
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

class Error {
  Error({
    this.isClientSafe,
    this.error,
    this.reason,
    this.details,
    this.message,
    this.errorType,
  });

  bool? isClientSafe;
  dynamic? error;
  String? reason;
  Details? details;
  String? message;
  String? errorType;

  factory Error.fromMap(Map<String, dynamic> json) => Error(
    isClientSafe: json["isClientSafe"] == null ? null : json["isClientSafe"],
    error: json["error"] == null ? null : json["error"],
    reason: json["reason"] == null ? null : json["reason"],
    details: json["details"] == null ? null : Details.fromMap(json["details"]),
    message: json["message"] == null ? null : json["message"],
    errorType: json["errorType"] == null ? null : json["errorType"],
  );

  Map<String, dynamic> toMap() => {
    "isClientSafe": isClientSafe == null ? null : isClientSafe,
    "error": error == null ? null : error,
    "reason": reason == null ? null : reason,
    "details": details == null ? null : details!.toMap(),
    "message": message == null ? null : message,
    "errorType": errorType == null ? null : errorType,
  };
}

class Details {
  Details({
    this.function,
    this.channelName,
  });

  String? function;
  String? channelName;

  factory Details.fromMap(Map<String, dynamic> json) => Details(
    function: json["function"] == null ? null : json["function"],
    channelName: json["channel_name"] == null ? null : json["channel_name"],
  );

  Map<String, dynamic> toMap() => {
    "function": function == null ? null : function,
    "channel_name": channelName == null ? null : channelName,
  };
}

