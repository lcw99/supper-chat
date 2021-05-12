// To parse this JSON data, do
//
//     final roomMembersResponse = roomMembersResponseFromMap(jsonString);

import 'package:rocket_chat_connector_flutter/models/user.dart';

class RoomMembersResponse {
  RoomMembersResponse({
    this.users,
    this.count,
    this.offset,
    this.total,
    this.success,
  });

  List<User>? users;
  int? count;
  int? offset;
  int? total;
  bool? success;

  factory RoomMembersResponse.fromMap(Map<String, dynamic> json) => RoomMembersResponse(
    users: List<User>.from(json["members"].map((x) => User.fromMap(x))),
    count: json["count"],
    offset: json["offset"],
    total: json["total"],
    success: json["success"],
  );

  Map<String, dynamic> toMap() => {
    "users": List<dynamic>.from(users!.map((x) => x.toMap())),
    "count": count,
    "offset": offset,
    "total": total,
    "success": success,
  };
}

