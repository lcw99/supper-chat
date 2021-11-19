// To parse this JSON data, do
//
//     final rcFile = rcFileFromMap(jsonString);

import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/user.dart';

import 'image_dimensions.dart';

class RcFile {
  RcFile({
    this.id,
    this.name,
    this.size,
    this.type,
    this.rid,
    this.userId,
    this.store,
    this.updatedAt,
    this.instanceId,
    this.identify,
    this.complete,
    this.etag,
    this.path,
    this.progress,
    this.token,
    this.uploadedAt,
    this.uploading,
    this.url,
    this.description,
    this.typeGroup,
    this.user,
  });

  String? id;
  String? name;
  int? size;
  String? type;
  String? rid;
  String? userId;
  String? store;
  DateTime? updatedAt;
  String? instanceId;
  Identify? identify;
  bool? complete;
  String? etag;
  String? path;
  int? progress;
  String? token;
  DateTime? uploadedAt;
  bool? uploading;
  String? url;
  String? description;
  String? typeGroup;
  User? user;

  factory RcFile.fromMap(Map<String, dynamic> json) => RcFile(
    id: json["_id"] == null ? null : json["_id"],
    name: json["name"] == null ? null : json["name"],
    size: json["size"] == null ? null : json["size"],
    type: json["type"] == null ? null : json["type"],
    rid: json["rid"] == null ? null : json["rid"],
    userId: json["userId"] == null ? null : json["userId"],
    store: json["store"] == null ? null : json["store"],
    updatedAt: json["_updatedAt"] == null ? null : DateTime.parse(json["_updatedAt"]),
    instanceId: json["instanceId"] == null ? null : json["instanceId"],
    identify: json["identify"] == null ? null : Identify.fromMap(json["identify"]),
    complete: json["complete"] == null ? null : json["complete"],
    etag: json["etag"] == null ? null : json["etag"],
    path: json["path"] == null ? null : json["path"],
    progress: json["progress"] == null ? null : json["progress"],
    token: json["token"] == null ? null : json["token"],
    uploadedAt: json["uploadedAt"] == null ? null : DateTime.parse(json["uploadedAt"]),
    uploading: json["uploading"] == null ? null : json["uploading"],
    url: json["url"] == null ? null : json["url"],
    description: json["description"] == null ? null : json["description"],
    typeGroup: json["typeGroup"] == null ? null : json["typeGroup"],
    user: json["user"] == null ? null : User.fromMap(json["user"]),
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "name": name == null ? null : name,
    "size": size == null ? null : size,
    "type": type == null ? null : type,
    "rid": rid == null ? null : rid,
    "userId": userId == null ? null : userId,
    "store": store == null ? null : store,
    "_updatedAt": updatedAt == null ? null : updatedAt!.toIso8601String(),
    "instanceId": instanceId == null ? null : instanceId,
    "identify": identify == null ? null : identify!.toMap(),
    "complete": complete == null ? null : complete,
    "etag": etag == null ? null : etag,
    "path": path == null ? null : path,
    "progress": progress == null ? null : progress,
    "token": token == null ? null : token,
    "uploadedAt": uploadedAt == null ? null : uploadedAt!.toIso8601String(),
    "uploading": uploading == null ? null : uploading,
    "url": url == null ? null : url,
    "description": description == null ? null : description,
    "typeGroup": typeGroup == null ? null : typeGroup,
    "user": user == null ? null : user!.toMap(),
  };
}

class Identify {
  Identify({
    this.format,
    this.size,
  });

  String? format;
  ImageDimensions? size;

  factory Identify.fromMap(Map<String, dynamic> json) => Identify(
    format: json["format"] == null ? null : json["format"],
    size: json["size"] == null ? null : ImageDimensions.fromMap(json["size"]),
  );

  Map<String, dynamic> toMap() => {
    "format": format == null ? null : format,
    "size": size == null ? null : size!.toMap(),
  };
}

