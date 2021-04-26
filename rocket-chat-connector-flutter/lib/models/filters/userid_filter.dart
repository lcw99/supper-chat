import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/filters/filter.dart';

class UserIdFilter extends Filter {
  String userId;

  UserIdFilter(this.userId);

  Map<String, dynamic> toMap() => {
    'userId': userId,
  };

  @override
  String toString() {
    return 'UserIdFilter{userId: $userId}';
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
