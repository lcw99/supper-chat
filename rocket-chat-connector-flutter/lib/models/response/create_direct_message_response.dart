// To parse this JSON data, do
//
//     final createDirectMessageResponse = createDirectMessageResponseFromMap(jsonString);


class CreateDirectMessageResponse {
  CreateDirectMessageResponse({
    this.room,
    this.success,
  });

  Room? room;
  bool? success;

  factory CreateDirectMessageResponse.fromMap(Map<String, dynamic> json) => CreateDirectMessageResponse(
    room: json["room"] == null ? null : Room.fromMap(json["room"]),
    success: json["success"] == null ? null : json["success"],
  );

  Map<String, dynamic> toMap() => {
    "room": room == null ? null : room!.toMap(),
    "success": success == null ? null : success,
  };
}

class Room {
  Room({
    this.t,
    this.rid,
    this.usernames,
  });

  String? t;
  String? rid;
  List<String>? usernames;

  factory Room.fromMap(Map<String, dynamic> json) => Room(
    t: json["t"] == null ? null : json["t"],
    rid: json["rid"] == null ? null : json["rid"],
    usernames: json["usernames"] == null ? null : List<String>.from(json["usernames"].map((x) => x)),
  );

  Map<String, dynamic> toMap() => {
    "t": t == null ? null : t,
    "rid": rid == null ? null : rid,
    "usernames": usernames == null ? null : List<dynamic>.from(usernames!.map((x) => x)),
  };
}
