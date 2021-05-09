import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/filters/filter.dart';

class UserIdFilter extends Filter {
  String? userId;
  String? username;

  UserIdFilter({this.userId, this.username});

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    if (userId != null) map['userId'] = userId;
    if (username != null) map['username'] = username;
    return map;
  }

  @override
  String toString() {
    return jsonEncode(this.toMap());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UserIdFilter &&
              runtimeType == other.runtimeType &&
              userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
