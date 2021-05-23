// To parse this JSON data, do
//
//     final customEmojiResponse = customEmojiResponseFromMap(jsonString);

import 'dart:convert';
import '../custom_emoji.dart';

class CustomEmojiResponse {
  CustomEmojiResponse({
    this.emojis,
    this.success = false,
  });

  Emojis? emojis;
  bool? success;

  factory CustomEmojiResponse.fromMap(Map<String, dynamic> json) => CustomEmojiResponse(
    emojis: json["emojis"] == null ? null : Emojis.fromMap(json["emojis"]),
    success: json["success"] == null ? null : json["success"],
  );

  Map<String, dynamic> toMap() => {
    "emojis": emojis == null ? null : emojis!.toMap(),
    "success": success == null ? null : success,
  };
}

class Emojis {
  Emojis({
    this.update,
    this.remove,
  });

  List<CustomEmoji>? update;
  List<CustomEmoji>? remove;

  factory Emojis.fromMap(Map<String, dynamic> json) => Emojis(
    update: json["update"] == null ? null : List<CustomEmoji>.from(json["update"].map((x) => CustomEmoji.fromMap(x))),
    remove: json["remove"] == null ? null : List<CustomEmoji>.from(json["remove"].map((x) => CustomEmoji.fromMap(x))),
  );

  Map<String, dynamic> toMap() => {
    "update": update == null ? null : List<dynamic>.from(update!.map((x) => x.toMap())),
    "remove": remove == null ? null : List<dynamic>.from(remove!.map((x) => x.toMap())),
  };
}

