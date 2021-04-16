// To parse this JSON data, do
//
//     final room = roomFromMap(jsonString);

import 'dart:convert';

Room roomFromMap(String str) => Room.fromMap(json.decode(str));

String roomToMap(Room data) => json.encode(data.toMap());

class Room {
  Room({
    this.id,
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
  });

  String? id;
  String? name;
  String? fname;
  String? t;
  int? usersCount;
  RoomU? u;
  CustomFields? customFields;
  bool? broadcast;
  bool? encrypted;
  bool? ro;
  bool? roomDefault;
  DateTime? updatedAt;
  String? description;
  LastMessage? lastMessage;
  DateTime? lm;
  String? avatarETag;
  String? topic;
  String? announcement;

  factory Room.fromMap(Map<String, dynamic> json) => Room(
    id: json["_id"] == null ? null : json["_id"],
    name: json["name"] == null ? null : json["name"],
    fname: json["fname"] == null ? null : json["fname"],
    t: json["t"] == null ? null : json["t"],
    usersCount: json["usersCount"] == null ? null : json["usersCount"],
    u: json["u"] == null ? null : RoomU.fromMap(json["u"]),
    customFields: json["customFields"] == null ? null : CustomFields.fromMap(json["customFields"]),
    broadcast: json["broadcast"] == null ? null : json["broadcast"],
    encrypted: json["encrypted"] == null ? null : json["encrypted"],
    ro: json["ro"] == null ? null : json["ro"],
    roomDefault: json["default"] == null ? null : json["default"],
    updatedAt: json["_updatedAt"] == null ? null : DateTime.parse(json["_updatedAt"]),
    description: json["description"] == null ? null : json["description"],
    lastMessage: json["lastMessage"] == null ? null : LastMessage.fromMap(json["lastMessage"]),
    lm: json["lm"] == null ? null : DateTime.parse(json["lm"]),
    avatarETag: json["avatarETag"] == null ? null : json["avatarETag"],
    topic: json["topic"] == null ? null : json["topic"],
    announcement: json["announcement"] == null ? null : json["announcement"],
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "name": name == null ? null : name,
    "fname": fname == null ? null : fname,
    "t": t == null ? null : t,
    "usersCount": usersCount == null ? null : usersCount,
    "u": u == null ? null : u!.toMap(),
    "customFields": customFields == null ? null : customFields!.toMap(),
    "broadcast": broadcast == null ? null : broadcast,
    "encrypted": encrypted == null ? null : encrypted,
    "ro": ro == null ? null : ro,
    "default": roomDefault == null ? null : roomDefault,
    "_updatedAt": updatedAt == null ? null : updatedAt!.toIso8601String(),
    "description": description == null ? null : description,
    "lastMessage": lastMessage == null ? null : lastMessage!.toMap(),
    "lm": lm == null ? null : lm!.toIso8601String(),
    "avatarETag": avatarETag == null ? null : avatarETag,
    "topic": topic == null ? null : topic,
    "announcement": announcement == null ? null : announcement,
  };
}

class CustomFields {
  CustomFields();

  factory CustomFields.fromMap(Map<String, dynamic> json) => CustomFields(
  );

  Map<String, dynamic> toMap() => {
  };
}

class LastMessage {
  LastMessage({
    this.id,
    this.rid,
    this.msg,
    this.ts,
    this.u,
    this.updatedAt,
    this.mentions,
    this.channels,
  });

  String? id;
  String? rid;
  String? msg;
  DateTime? ts;
  LastMessageU? u;
  DateTime? updatedAt;
  List<dynamic>? mentions;
  List<dynamic>? channels;

  factory LastMessage.fromMap(Map<String, dynamic> json) => LastMessage(
    id: json["_id"] == null ? null : json["_id"],
    rid: json["rid"] == null ? null : json["rid"],
    msg: json["msg"] == null ? null : json["msg"],
    ts: json["ts"] == null ? null : DateTime.parse(json["ts"]),
    u: json["u"] == null ? null : LastMessageU.fromMap(json["u"]),
    updatedAt: json["_updatedAt"] == null ? null : DateTime.parse(json["_updatedAt"]),
    mentions: json["mentions"] == null ? null : List<dynamic>.from(json["mentions"].map((x) => x)),
    channels: json["channels"] == null ? null : List<dynamic>.from(json["channels"].map((x) => x)),
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "rid": rid == null ? null : rid,
    "msg": msg == null ? null : msg,
    "ts": ts == null ? null : ts!.toIso8601String(),
    "u": u == null ? null : u!.toMap(),
    "_updatedAt": updatedAt == null ? null : updatedAt!.toIso8601String(),
    "mentions": mentions == null ? null : List<dynamic>.from(mentions!.map((x) => x)),
    "channels": channels == null ? null : List<dynamic>.from(channels!.map((x) => x)),
  };
}

class LastMessageU {
  LastMessageU({
    this.id,
    this.username,
    this.name,
  });

  String? id;
  String? username;
  String? name;

  factory LastMessageU.fromMap(Map<String, dynamic> json) => LastMessageU(
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

class RoomU {
  RoomU({
    this.id,
    this.username,
  });

  String? id;
  String? username;

  factory RoomU.fromMap(Map<String, dynamic> json) => RoomU(
    id: json["_id"] == null ? null : json["_id"],
    username: json["username"] == null ? null : json["username"],
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "username": username == null ? null : username,
  };
}
