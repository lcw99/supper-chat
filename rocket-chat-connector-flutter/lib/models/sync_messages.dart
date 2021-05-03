import 'dart:convert';
import 'message.dart';

SyncMessages syncMessagesFromMap(String str) => SyncMessages.fromMap(json.decode(str));

String syncMessagesToMap(SyncMessages data) => json.encode(data.toMap());

class SyncMessages {
  SyncMessages({
    this.result,
    this.success,
  });

  SyncMessageResult? result;
  bool? success;

  factory SyncMessages.fromMap(Map<String, dynamic> json) => SyncMessages(
    result: json["result"] == null ? null : SyncMessageResult.fromMap(json["result"]),
    success: json["success"] == null ? null : json["success"],
  );

  Map<String, dynamic> toMap() => {
    "result": result == null ? null : result!.toMap(),
    "success": success == null ? null : success,
  };
}

class SyncMessageResult {
  List<Message>? updated;
  List<Message>? deleted;

  SyncMessageResult({ this.updated, this.deleted });

  SyncMessageResult.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      if (json['updated'] != null) {
        List<dynamic> jsonList = json['updated'].runtimeType == String //
            ? jsonDecode(json['updated'])
            : json['updated'];
        updated = jsonList
            .where((json) => json != null)
            .map((json) => Message.fromMap(json))
            .toList();
      } else {
        updated = null;
      }

      if (json['deleted'] != null) {
        List<dynamic> jsonList = json['deleted'].runtimeType == String //
            ? jsonDecode(json['deleted'])
            : json['deleted'];
        deleted = jsonList
            .where((json) => json != null)
            .map((json) => Message.fromMap(json))
            .toList();
      } else {
        deleted = null;
      }
    }
  }

  Map<String, dynamic>? toMap() {
    Map<String, dynamic> map = {};
    if (updated != null) {
      map['updated'] = updated
          ?.where((json) => json != null)
          ?.map((message) => message.toMap())
          ?.toList() ??
          [];
    }

    if (deleted != null) {
      map['deleted'] = deleted
          ?.where((json) => json != null)
          ?.map((message) => message.toMap())
          ?.toList() ??
          [];
    }
  }

  @override
  String toString() {
    return jsonEncode(this.toMap());
  }

}
