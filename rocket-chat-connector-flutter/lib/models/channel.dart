import 'package:collection/collection.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';
import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';

class Channel {
  String? id;
  String? name;
  String? t;
  List<String>? usernames;
  int? msgs;
  User? user;
  DateTime? ts;
  String? avatarETag;
  String? description;
  String? topic;
  String? announcement;

  Channel({
    this.id,
    this.name,
    this.t,
    this.usernames,
    this.msgs,
    this.user,
    this.ts,
    this.avatarETag,
    this.description,
    this.topic,
    this.announcement,
  });

  Channel.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      id = json['_id'];
      name = json['name'];
      t = json['t'];
      usernames = json['usernames'] != null ? List<String>.from(json['usernames']) : null;
      msgs = json['msgs'];
      user = json['u'] != null ? User.fromMap(json['u']) : null;
      ts = jsonToDateTime(json['ts']);
      avatarETag = json['avatarETag'];
      description = json['description'];
      topic = json['topic'];
      announcement = json['announcement'];
    }
  }

  Map<String, dynamic> toMap() => {
        '_id': id,
        'name': name,
        't': t,
        'usernames': usernames,
        'msgs': msgs,
        'u': user != null ? user!.toMap() : null,
        'ts': ts != null ? ts!.toIso8601String() : null,
        'avatarETag': avatarETag,
        'description': description,
        'topic': topic,
        'announcement': announcement,
      };

  @override
  String toString() {
    return 'Channel{_id: $id, name: $name, t: $t, usernames: $usernames, msgs: $msgs, user: $user, ts: $ts, '
        'avatarETag: $avatarETag}, description: $description, topic: $topic, announcement: $announcement';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Channel &&
          id == other.id;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      t.hashCode ^
      usernames.hashCode ^
      msgs.hashCode ^
      user.hashCode ^
      avatarETag.hashCode ^
      description.hashCode ^
      topic.hashCode ^
      announcement.hashCode ^
      ts.hashCode;
}
