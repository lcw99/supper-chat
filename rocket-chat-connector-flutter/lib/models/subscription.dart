// To parse this JSON data, do
//
//     final subscription = subscriptionFromMap(jsonString);

import 'dart:convert';
import 'package:rocket_chat_connector_flutter/models/message_user.dart';

Subscription subscriptionFromMap(String str) => Subscription.fromMap(json.decode(str));

String subscriptionToMap(Subscription data) => json.encode(data.toMap());

class Subscription {
  Subscription({
    this.id,
    this.open,
    this.alert,
    this.unread,
    this.userMentions,
    this.groupMentions,
    this.ts,
    this.rid,
    this.name,
    this.fname,
    this.customFields,
    this.t,
    this.u,
    this.updatedAt,
    this.ls,
    this.blocked,
  });

  String? id;
  bool? open;
  bool? alert;
  int? unread;
  int? userMentions;
  int? groupMentions;
  DateTime? ts;
  String? rid;
  String? name;
  String? fname;
  CustomFields? customFields;
  String? t;
  MessageUser? u;
  DateTime? updatedAt;
  DateTime? ls;
  bool? blocked;

  factory Subscription.fromMap(Map<String, dynamic> json) => Subscription(
    id: json["_id"] == null ? null : json["_id"],
    open: json["open"] == null ? null : json["open"],
    alert: json["alert"] == null ? null : json["alert"],
    unread: json["unread"] == null ? null : json["unread"],
    userMentions: json["userMentions"] == null ? null : json["userMentions"],
    groupMentions: json["groupMentions"] == null ? null : json["groupMentions"],
    ts: json['ts'] != null
        ? (json['ts'] is String
        ? DateTime.parse(json['ts'])
        : DateTime.fromMillisecondsSinceEpoch(json['ts']['\$date']!))
        : null,
    rid: json["rid"] == null ? null : json["rid"],
    name: json["name"] == null ? null : json["name"],
    fname: json["fname"] == null ? null : json["fname"],
    customFields: json["customFields"] == null ? null : CustomFields.fromMap(json["customFields"]),
    t: json["t"] == null ? null : json["t"],
    u: json["u"] == null ? null : MessageUser.fromMap(json["u"]),
    updatedAt: json['_updatedAt'] != null
        ? (json['_updatedAt'] is String
        ? DateTime.parse(json['_updatedAt'])
        : DateTime.fromMillisecondsSinceEpoch(json['_updatedAt']['\$date']!))
        : null,
    ls: json['ls'] != null
        ? (json['ls'] is String
        ? DateTime.parse(json['ls'])
        : DateTime.fromMillisecondsSinceEpoch(json['ls']['\$date']!))
        : null,
    blocked: json["blocked"] == null ? null : json["blocked"],
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "open": open == null ? null : open,
    "alert": alert == null ? null : alert,
    "unread": unread == null ? null : unread,
    "userMentions": userMentions == null ? null : userMentions,
    "groupMentions": groupMentions == null ? null : groupMentions,
    "ts": ts == null ? null : ts!.toIso8601String(),
    "rid": rid == null ? null : rid,
    "name": name == null ? null : name,
    "fname": fname == null ? null : fname,
    "customFields": customFields == null ? null : customFields!.toMap(),
    "t": t == null ? null : t,
    "u": u == null ? null : u!.toMap(),
    "_updatedAt": updatedAt == null ? null : updatedAt!.toIso8601String(),
    "ls": ls == null ? null : ls!.toIso8601String(),
    "blocked": blocked == null ? null : blocked,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Subscription &&
              id == other.id;
  @override
  int get hashCode =>
      id.hashCode;

}

class CustomFields {
  CustomFields();

  factory CustomFields.fromMap(Map<String, dynamic> json) => CustomFields(
  );

  Map<String, dynamic> toMap() => {
  };
}

