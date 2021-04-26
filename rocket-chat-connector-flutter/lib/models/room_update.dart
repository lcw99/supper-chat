// To parse this JSON data, do
//
//     final roomUpdate = roomUpdateFromMap(jsonString);

import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/room.dart';

RoomUpdate roomUpdateFromMap(String str) => RoomUpdate.fromMap(json.decode(str));

String roomUpdateToMap(RoomUpdate data) => json.encode(data.toMap());

class RoomUpdate {
  RoomUpdate({
    this.update,
    this.remove,
    this.success,
  });

  List<Room>? update;
  List<Room>? remove;
  bool? success;

  factory RoomUpdate.fromMap(Map<String, dynamic> json) => RoomUpdate(
    update: List<Room>.from(json["update"].map((x) => Room.fromMap(x))),
    remove: List<Room>.from(json["remove"].map((x) => Room.fromMap(x))),
    success: json["success"],
  );

  Map<String, dynamic> toMap() => {
    "update": List<Room>.from(update!.map((x) => x.toMap())),
    "remove": List<Room>.from(remove!.map((x) => x.toMap())),
    "success": success,
  };
}
