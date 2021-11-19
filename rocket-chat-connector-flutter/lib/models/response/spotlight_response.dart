import 'package:rocket_chat_connector_flutter/models/room.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

class SpotlightResponse {
  SpotlightResponse({
    this.users,
    this.rooms,
    this.success,
  });

  List<User>? users;
  List<Room>? rooms;
  bool? success;

  factory SpotlightResponse.fromMap(Map<String, dynamic> json) => SpotlightResponse(
    users: List<User>.from(json["users"].map((x) => User.fromMap(x))),
    rooms: List<Room>.from(json["rooms"].map((x) => Room.fromMap(x))),
    success: json["success"],
  );

  Map<String, dynamic> toMap() => {
    "users": List<dynamic>.from(users!.map((x) => x.toMap())),
    "rooms": List<dynamic>.from(rooms!.map((x) => x.toMap())),
    "success": success,
  };
}