import 'package:flutter/foundation.dart';
import 'package:rocket_chat_connector_flutter/models/channel.dart';

class ChannelListResponse {
  List<Channel>? channelList = [];
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
          Channel c = Channel.fromMap(e);
          channelList!.add(c);
        }
      } else
        debugPrint("channel count=null");
      success = json['success'];
    } else {
      debugPrint("json=null");
    }
  }

  @override
  String toString() {
    return 'MessageResponse{channels: $channelList, success: $success}';
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
