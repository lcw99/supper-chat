// To parse this JSON data, do
//
//     final roomMembersResponse = roomMembersResponseFromMap(jsonString);

import 'package:rocket_chat_connector_flutter/models/response/query_response.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

class RoomMembersResponse extends QueryResponse {
  RoomMembersResponse({
    this.users,
    count,
    offset,
    total,
    success,
  }) : super(count: count, offset: offset, total: total, success: success);

  List<User>? users;

  factory RoomMembersResponse.fromMap(Map<String, dynamic> json) {
    var p = QueryResponse.fromMap(json);
    return RoomMembersResponse(
      users: List<User>.from(json["members"].map((x) => User.fromMap(x))),
      count: p.count,
      offset: p.offset,
      total: p.total,
      success: p.success,
    );
  }

  Map<String, dynamic> toMap() {
    var p = super.toMap();
    p["users"] = List<dynamic>.from(users!.map((x) => x.toMap()));
    return p;
  }
}

