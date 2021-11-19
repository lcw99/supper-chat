// To parse this JSON data, do
//
//     final syncThreadListResponse = syncThreadListResponseFromMap(jsonString);

import 'dart:convert';

import '../message.dart';

class SyncThreadListResponse {
  SyncThreadListResponse({
    this.threads,
    this.success,
  });

  Threads? threads;
  bool? success;

  factory SyncThreadListResponse.fromMap(Map<String, dynamic> json) => SyncThreadListResponse(
    threads: json["threads"] == null ? null : Threads.fromMap(json["threads"]),
    success: json["success"] == null ? null : json["success"],
  );

  Map<String, dynamic> toMap() => {
    "threads": threads == null ? null : threads!.toMap(),
    "success": success == null ? null : success,
  };
}

class Threads {
  Threads({
    this.update,
    this.remove,
  });

  List<Message>? update;
  List<Message>? remove;

  factory Threads.fromMap(Map<String, dynamic> json) => Threads(
    update: json["update"] == null ? null : List<Message>.from(json["update"].map((x) => Message.fromMap(x))),
    remove: json["remove"] == null ? null : List<Message>.from(json["remove"].map((x) => Message.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "update": update == null ? null : List<dynamic>.from(update!.map((x) => x.toMap())),
    "remove": remove == null ? null : List<dynamic>.from(remove!.map((x) => x.toMap())),
  };
}

