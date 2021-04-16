import 'package:rocket_chat_connector_flutter/models/channel.dart';
import 'package:rocket_chat_connector_flutter/models/filters/filter.dart';

class UpdatedSinceFilter extends Filter {
  DateTime updatedSince;

  UpdatedSinceFilter(this.updatedSince);

  Map<String, dynamic> toMap() => {
    'updatedSince': updatedSince.toIso8601String(),
  };

  @override
  String toString() {
    return 'UpdatedSinceFilter{updateSince: $updatedSince}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is UpdatedSinceFilter &&
              runtimeType == other.runtimeType &&
              updatedSince == other.updatedSince;

  @override
  int get hashCode => updatedSince.hashCode;
}
