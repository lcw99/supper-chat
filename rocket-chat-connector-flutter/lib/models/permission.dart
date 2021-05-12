// To parse this JSON data, do
//
//     final permission = permissionFromMap(jsonString);

import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';

Permission permissionFromMap(String str) => Permission.fromMap(json.decode(str));

String permissionToMap(Permission data) => json.encode(data.toMap());

class Permission {
  Permission({
    this.id,
    this.roles,
    this.updatedAt,
    this.meta,
    this.loki,
  });

  String? id;
  List<String>? roles;
  DateTime? updatedAt;
  Meta? meta;
  int? loki;

  factory Permission.fromMap(Map<String, dynamic> json) => Permission(
    id: json["_id"],
    roles: List<String>.from(json["roles"].map((x) => x)),
    updatedAt: jsonToDateTime(json['_updatedAt']),
    meta: json["meta"] != null ? Meta.fromMap(json["meta"]) : null,
    loki: json["\$loki"] != null ? json["\$loki"] : null,
  );

  Map<String, dynamic> toMap() => {
    "_id": id,
    "roles": List<dynamic>.from(roles!.map((x) => x)),
    "_updatedAt": { '\$date': updatedAt!.millisecondsSinceEpoch.toString() },
    "meta": meta!.toMap(),
    "\$loki": loki,
  };
}

class Meta {
  Meta({
    this.revision,
    this.created,
    this.version,
    this.updated,
  });

  int? revision;
  int? created;
  int? version;
  int? updated;

  factory Meta.fromMap(Map<String, dynamic> json) => Meta(
    revision: json['revision'] != null ? json["revision"] : null,
    created: json['created'] != null ? json["created"] : null,
    version: json['version'] != null ? json["version"] : null,
    updated: json['updated'] != null ? json["updated"] : null,
  );

  Map<String, dynamic> toMap() => {
    "revision": revision,
    "created": created,
    "version": version,
    "updated": updated,
  };
}

