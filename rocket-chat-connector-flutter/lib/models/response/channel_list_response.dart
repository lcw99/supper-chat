import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:rocket_chat_connector_flutter/models/response/response_base.dart';
import 'package:rocket_chat_connector_flutter/models/room.dart';

class ChannelListResponse extends ResponseBase {
  List<Room>? channelList = [];
  bool? success;

  ChannelListResponse({
    this.channelList,
    this.success = false,
  });

  ChannelListResponse.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      List? l = json['channels'] != null ? List.from(json['channels']) : null;
      if (l != null) {
        for (var e in l) {
          Room c = Room.fromMap(e);
          channelList!.add(c);
        }
      } else
        debugPrint("channel count=null");
      success = json['success'];
    } else {
      debugPrint("json=null");
    }
  }

  Map<String, dynamic> toMap() => {
    'channelList': channelList
        ?.where((json) => json != null)
        ?.map((channelList) => channelList.toMap())
        ?.toList() ??
        [],
    'success': success,
  };


  @override
  String toString() {
    return jsonEncode(this.toMap());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ChannelListResponse &&
              runtimeType == other.runtimeType &&
              channelList == other.channelList &&
              success == other.success;

  @override
  int get hashCode => channelList.hashCode ^ success.hashCode;
}
