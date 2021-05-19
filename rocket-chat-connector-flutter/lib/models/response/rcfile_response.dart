// To parse this JSON data, do
//
//     final roomMembersResponse = roomMembersResponseFromMap(jsonString);

import 'package:rocket_chat_connector_flutter/models/rc_file.dart';
import 'package:rocket_chat_connector_flutter/models/response/query_response.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

class RcFileResponse extends QueryResponse {
  RcFileResponse({
    this.files,
    count,
    offset,
    total,
    success,
  }) : super(count: count, offset: offset, total: total, success: success);

  List<RcFile>? files;

  factory RcFileResponse.fromMap(Map<String, dynamic> json) {
    var p = QueryResponse.fromMap(json);
    return RcFileResponse(
      files: List<RcFile>.from(json["files"].map((x) => RcFile.fromMap(x))),
      count: p.count,
      offset: p.offset,
      total: p.total,
      success: p.success,
    );
  }

  Map<String, dynamic> toMap() {
    var p = super.toMap();
    p["users"] = List<dynamic>.from(files!.map((x) => x.toMap()));
    return p;
  }
}

