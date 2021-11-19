import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:rocket_chat_connector_flutter/models/message_attachment.dart';

class MessageNew {
  String? alias;
  String? avatar;
  String? emoji;
  String? roomId;
  String? text;
  String? msg;
  String? tmid;
  List<MessageAttachment>? attachments;

  MessageNew({
    this.alias,
    this.avatar,
    this.emoji,
    this.roomId,
    this.text,
    this.msg,
    this.tmid,
    this.attachments,
  });

  MessageNew.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      alias = json['alias'];
      avatar = json['avatar'];
      emoji = json['emoji'];
      roomId = json['roomId'];
      tmid = json['tmid'];
      text = json['text'];
      msg = json['msg'];

      if (json['attachments'] != null) {
        List<dynamic> jsonList = json['attachments'].runtimeType == String //
            ? jsonDecode(json['attachments'])
            : json['attachments'];
        attachments = jsonList
            .where((json) => json != null)
            .map((json) => MessageAttachment.fromMap(json))
            .toList();
      } else {
        attachments = null;
      }
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};

    if (alias != null) {
      map['alias'] = alias;
    }

    if (avatar != null) {
      map['avatar'] = avatar;
    }
    if (emoji != null) {
      map['emoji'] = emoji;
    }
    if (roomId != null) {
      map['roomId'] = roomId;
    }
    if (tmid != null) {
      map['tmid'] = tmid;
    }
    if (text != null) {
      map['text'] = text;
    }
    if (msg != null) {
      map['msg'] = msg;
    }
    if (attachments != null) {
      map['attachments'] = attachments
              ?.where((json) => json != null)
              ?.map((attachment) => attachment.toMap())
              ?.toList() ??
          [];
    }

    return map;
  }

  @override
  String toString() {
    return jsonEncode(this.toMap());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageNew &&
          runtimeType == other.runtimeType &&
          alias == other.alias &&
          avatar == other.avatar &&
          emoji == other.emoji &&
          roomId == other.roomId &&
          text == other.text &&
          DeepCollectionEquality().equals(attachments, other.attachments);

  @override
  int get hashCode =>
      alias.hashCode ^
      avatar.hashCode ^
      emoji.hashCode ^
      roomId.hashCode ^
      text.hashCode ^
      attachments.hashCode;
}
