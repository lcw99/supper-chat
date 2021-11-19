// To parse this JSON data, do
//
//     final room = roomFromMap(jsonString);

import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/message.dart';
import 'package:rocket_chat_connector_flutter/models/subscription.dart';
import 'package:rocket_chat_connector_flutter/models/message_user.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';

Room roomFromMap(String str) => Room.fromMap(json.decode(str));

String roomToMap(Room data) => json.encode(data.toMap());

class Room {
  Room({
    this.id,
    this.rid,
    this.name,
    this.fname,
    this.t,
    this.usersCount,
    this.u,
    this.customFields,
    this.broadcast,
    this.encrypted,
    this.ro,
    this.roomDefault,
    this.updatedAt,
    this.description,
    this.lastMessage,
    this.lm,
    this.avatarETag,
    this.topic,
    this.announcement,
    this.usernames,
    this.uids,
    this.subscription,
    this.joinCodeRequired,
    this.error,
  });

  Subscription? subscription;

  String? id;
  String? rid;
  String? name;
  String? fname;
  String? t;
  int? usersCount;
  MessageUser? u;
  CustomFields? customFields;
  bool? broadcast;
  bool? encrypted;
  bool? ro;
  bool? roomDefault;
  DateTime? updatedAt;
  String? description;
  Message? lastMessage;
  DateTime? lm;
  String? avatarETag;
  String? topic;
  String? announcement;
  List<String>? usernames;
  List<String>? uids;
  String? roomAvatarUrl;
  bool? joinCodeRequired;
  String? error;

  factory Room.fromMap(Map<String, dynamic> json) => Room(
    id: json["_id"] == null ? null : json["_id"],
    rid: json["rid"] == null ? null : json["rid"],
    error: json["error"] == null ? null : json["error"],
    name: json["name"] == null ? null : json["name"],
    fname: json["fname"] == null ? null : json["fname"],
    t: json["t"] == null ? null : json["t"],
    usersCount: json["usersCount"] == null ? null : json["usersCount"],
    u: json["u"] == null ? null : MessageUser.fromMap(json["u"]),
    customFields: json["customFields"] == null ? null : CustomFields.fromMap(json["customFields"]),
    broadcast: json["broadcast"] == null ? null : json["broadcast"],
    encrypted: json["encrypted"] == null ? null : json["encrypted"],
    joinCodeRequired: json["joinCodeRequired"] == null ? null : json["joinCodeRequired"],
    ro: json["ro"] == null ? null : json["ro"],
    roomDefault: json["default"] == null ? null : json["default"],
    updatedAt: jsonToDateTime(json["_updatedAt"]),
    description: json["description"] == null ? null : json["description"],
    lastMessage: json["lastMessage"] == null ? null : Message.fromMap(json["lastMessage"]),
    lm: jsonToDateTime(json["lm"]),
    avatarETag: json["avatarETag"] == null ? null : json["avatarETag"],
    topic: json["topic"] == null ? null : json["topic"],
    announcement: json["announcement"] == null ? null : json["announcement"],
    usernames: json["usernames"] == null ? null : List<String>.from(json["usernames"].map((x) => x)),
    uids: json["uids"] == null ? null : List<String>.from(json["uids"].map((x) => x)),
    subscription: json["subscription"] == null ? null : Subscription.fromMap(json["subscription"]),
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "rid": rid == null ? null : rid,
    "name": name == null ? null : name,
    "fname": fname == null ? null : fname,
    "t": t == null ? null : t,
    "usersCount": usersCount == null ? null : usersCount,
    "u": u == null ? null : u!.toMap(),
    "customFields": customFields == null ? null : customFields!.toMap(),
    "broadcast": broadcast == null ? null : broadcast,
    "encrypted": encrypted == null ? null : encrypted,
    "joinCodeRequired": joinCodeRequired == null ? null : joinCodeRequired,
    "ro": ro == null ? null : ro,
    "default": roomDefault == null ? null : roomDefault,
    "_updatedAt": updatedAt == null ? null : updatedAt!.toIso8601String(),
    "description": description == null ? null : description,
    "lastMessage": lastMessage == null ? null : lastMessage!.toMap(),
    "lm": lm == null ? null : lm!.toIso8601String(),
    "avatarETag": avatarETag == null ? null : avatarETag,
    "topic": topic == null ? null : topic,
    "announcement": announcement == null ? null : announcement,
    "usernames": usernames == null ? null : List<dynamic>.from(usernames!.map((x) => x)),
    "uids": uids == null ? null : List<dynamic>.from(uids!.map((x) => x)),
    "subscription": subscription == null ? null : subscription!.toMap(),
  };
}

class CustomFields {
  CustomFields();

  factory CustomFields.fromMap(Map<String, dynamic> json) => CustomFields(
  );

  Map<String, dynamic> toMap() => {
  };
}


