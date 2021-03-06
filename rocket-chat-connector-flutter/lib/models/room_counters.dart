import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';

class RoomCounters {
  bool? joined;
  int? members;
  int? unreads;
  DateTime? unreadsFrom;
  int? msgs;
  DateTime? latest;
  int? userMentions;
  bool? success;

  RoomCounters({
    this.joined,
    this.members,
    this.unreads,
    this.unreadsFrom,
    this.msgs,
    this.latest,
    this.userMentions,
    this.success = false,
  });

  RoomCounters.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      joined = json['joined'];
      members = json['members'];
      unreads = json['unreads'] != null ? json['unreads'] : 0;
      unreadsFrom = jsonToDateTime(json['unreadsFrom']);
      msgs = json['msgs'];
      latest = jsonToDateTime(json['latest']);
      userMentions = json['userMentions'];
      success = json['success'];
    }
  }

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};

    if (joined != null) {
      map['joined'] = joined;
    }

    if (members != null) {
      map['members'] = members;
    }

    if (unreads != null) {
      map['unreads'] = unreads;
    }

    if (unreadsFrom != null) {
      map['unreadsFrom'] = unreadsFrom!.toIso8601String();
    }

    if (msgs != null) {
      map['msgs'] = msgs;
    }

    if (latest != null) {
      map['latest'] = latest!.toIso8601String();
    }

    if (userMentions != null) {
      map['userMentions'] = userMentions;
    }

    if (success != null) {
      map['success'] = success;
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
      other is RoomCounters &&
          runtimeType == other.runtimeType &&
          joined == other.joined &&
          members == other.members &&
          unreads == other.unreads &&
          unreadsFrom == other.unreadsFrom &&
          msgs == other.msgs &&
          latest == other.latest &&
          userMentions == other.userMentions &&
          success == other.success;

  @override
  int get hashCode =>
      joined.hashCode ^
      members.hashCode ^
      unreads.hashCode ^
      unreadsFrom.hashCode ^
      msgs.hashCode ^
      latest.hashCode ^
      userMentions.hashCode ^
      success.hashCode;
}
