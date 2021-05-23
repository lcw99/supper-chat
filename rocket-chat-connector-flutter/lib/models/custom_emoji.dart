// To parse this JSON data, do
//
//     final customEmoji = customEmojiFromMap(jsonString);

import 'dart:convert';

class CustomEmoji {
  CustomEmoji({
    this.id,
    this.name,
    this.aliases,
    this.extension,
    this.updatedAt,
  });

  String? id;
  String? name;
  List<String>? aliases;
  String? extension;
  DateTime? updatedAt;

  factory CustomEmoji.fromMap(Map<String, dynamic> json) => CustomEmoji(
    id: json["_id"] == null ? null : json["_id"],
    name: json["name"] == null ? null : json["name"],
    aliases: json["aliases"] == null ? null : List<String>.from(json["aliases"].map((x) => x)),
    extension: json["extension"] == null ? null : json["extension"],
    updatedAt: json["_updatedAt"] == null ? null : DateTime.parse(json["_updatedAt"]),
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "name": name == null ? null : name,
    "aliases": aliases == null ? null : List<dynamic>.from(aliases!.map((x) => x)),
    "extension": extension == null ? null : extension,
    "_updatedAt": updatedAt == null ? null : updatedAt!.toIso8601String(),
  };
}
