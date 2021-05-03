import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'filter.dart';

class ChannelHistoryFilter extends Filter {
  DateTime? latest;
  DateTime? oldest;
  bool? inclusive;
  int? offset;
  int? count;
  bool? unreads;
  String? roomId;

  ChannelHistoryFilter({
    this.latest,
    this.oldest,
    this.inclusive,
    this.offset,
    this.count,
    this.unreads,
    this.roomId,
  }) : super();

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'latest': latest != null ? latest!.toIso8601String() : null,
        'oldest': oldest != null ? oldest!.toIso8601String() : null,
        'inclusive': inclusive,
        'offset': offset,
        'count': count,
        'unreads': unreads
      };

  @override
  String toString() {
    return jsonEncode(this.toMap());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is ChannelHistoryFilter &&
          runtimeType == other.runtimeType &&
          latest == other.latest &&
          oldest == other.oldest &&
          inclusive == other.inclusive &&
          offset == other.offset &&
          count == other.count &&
          roomId == other.roomId &&
          unreads == other.unreads;

  @override
  int get hashCode =>
      super.hashCode ^
      latest.hashCode ^
      oldest.hashCode ^
      inclusive.hashCode ^
      offset.hashCode ^
      count.hashCode ^
      roomId.hashCode ^
      unreads.hashCode;
}
