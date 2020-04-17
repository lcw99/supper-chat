import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/message_attachment.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

class Message {
  String _id;
  String alias;
  String msg;
  bool parseUrls;
  bool groupable;
  DateTime ts;
  User user;
  String rid;
  DateTime _updatedAt;
  List<MessageAttachment> attachments;

  Message({
    this.alias,
    this.msg,
    this.parseUrls,
    this.groupable,
    this.ts,
    this.user,
    this.rid,
    this.attachments,
  });

  Message.fromMap(Map<String, dynamic> json) {
    if (json != null) {
      alias = json['alias'];
      msg = json['msg'];
      parseUrls = json['parseUrls'];
      groupable = json['groupable'];
      ts = DateTime.parse(json['ts']);
      user = json['u'] != null ? User.fromMap(json['u']) : null;
      rid = json['rid'];
      _updatedAt = json['_updatedAt'] != null ? DateTime.parse(json['_updatedAt']) : null;
      _id = json['_id'];

      if (json['attachments'] != null) {
        List<dynamic> jsonList = json['attachments'].runtimeType == String //
            ? jsonDecode(json['attachments'])
            : json['attachments'];
        attachments = jsonList.where((json) => json != null).map((json) => MessageAttachment.fromMap(json)).toList();
      } else {
        attachments = null;
      }
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};

    if (_id != null) {
      map['_id'] = _id;
    }
    if (alias != null) {
      map['alias'] = alias;
    }
    if (msg != null) {
      map['msg'] = msg;
    }
    if (parseUrls != null) {
      map['parseUrls'] = parseUrls;
    }
    if (groupable != null) {
      map['groupable'] = groupable;
    }
    if (ts != null) {
      map['ts'] = ts.toIso8601String();
    }
    if (user != null) {
      map['u'] = user != null ? user.toMap() : null;
    }
    if (rid != null) {
      map['rid'] = rid;
    }
    if (_updatedAt != null) {
      map['_updatedAt'] = _updatedAt.toIso8601String();
    }
    if (attachments != null) {
      map['attachments'] = attachments?.where((json) => json != null)?.map((attachment) => attachment.toMap())?.toList() ?? [];
    }

    return map;
  }

  @override
  String toString() {
    return 'Message{alias: $alias, msg: $msg, parseUrls: $parseUrls, groupable: $groupable, ts: $ts, user: $user, rid: $rid, _updatedAt: $_updatedAt, _id: $_id, attachments: $attachments}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Message &&
          runtimeType == other.runtimeType &&
          alias == other.alias &&
          msg == other.msg &&
          parseUrls == other.parseUrls &&
          groupable == other.groupable &&
          ts == other.ts &&
          user == other.user &&
          rid == other.rid &&
          _updatedAt == other._updatedAt &&
          _id == other._id &&
          attachments == other.attachments;

  @override
  int get hashCode =>
      alias.hashCode ^
      msg.hashCode ^
      parseUrls.hashCode ^
      groupable.hashCode ^
      ts.hashCode ^
      user.hashCode ^
      rid.hashCode ^
      _updatedAt.hashCode ^
      _id.hashCode ^
      attachments.hashCode;
}
