// To parse this JSON data, do
//
//     final findOrCreateInviteResponse = findOrCreateInviteResponseFromMap(jsonString);

import 'dart:convert';

class FindOrCreateInviteResponse {
  FindOrCreateInviteResponse({
    this.id,
    this.days,
    this.maxUses,
    this.rid,
    this.userId,
    this.createdAt,
    this.expires,
    this.updatedAt,
    this.uses,
    this.url,
    this.success,
  });

  String? id;
  int? days;
  int? maxUses;
  String? rid;
  String? userId;
  DateTime? createdAt;
  DateTime? expires;
  DateTime? updatedAt;
  int? uses;
  String? url;
  bool? success;

  factory FindOrCreateInviteResponse.fromMap(Map<String, dynamic> json) => FindOrCreateInviteResponse(
    id: json["_id"],
    days: json["days"],
    maxUses: json["maxUses"],
    rid: json["rid"],
    userId: json["userId"],
    createdAt: DateTime.parse(json["createdAt"]),
    expires: json["expires"] == null ? null : DateTime.parse(json["expires"]),
    updatedAt: DateTime.parse(json["_updatedAt"]),
    uses: json["uses"],
    url: json["url"],
    success: json["success"],
  );

  Map<String, dynamic> toMap() => {
    "_id": id,
    "days": days,
    "maxUses": maxUses,
    "rid": rid,
    "userId": userId,
    "createdAt": createdAt!.toIso8601String(),
    "expires": expires!.toIso8601String(),
    "_updatedAt": updatedAt!.toIso8601String(),
    "uses": uses,
    "url": url,
    "success": success,
  };
}
