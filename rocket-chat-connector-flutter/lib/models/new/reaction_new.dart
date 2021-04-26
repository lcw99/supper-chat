// To parse this JSON data, do
//
//     final welcome = welcomeFromMap(jsonString);

import 'dart:convert';

ReactionNew welcomeFromMap(String str) => ReactionNew.fromMap(json.decode(str));

String welcomeToMap(ReactionNew data) => json.encode(data.toMap());

class ReactionNew {
  ReactionNew({
    this.emoji,
    this.messageId,
    this.shouldReact,
  });

  String? emoji;
  String? messageId;
  bool? shouldReact;

  factory ReactionNew.fromMap(Map<String, dynamic> json) => ReactionNew(
    emoji: json["emoji"] == null ? null : json["emoji"],
    messageId: json["messageId"] == null ? null : json["messageId"],
    shouldReact: json["shouldReact"] == null ? null : json["shouldReact"],
  );

  Map<String, dynamic> toMap() => {
    "emoji": emoji == null ? null : emoji,
    "messageId": messageId == null ? null : messageId,
    "shouldReact": shouldReact == null ? null : shouldReact,
  };
}
