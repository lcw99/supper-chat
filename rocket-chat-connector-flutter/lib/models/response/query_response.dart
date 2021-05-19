
import 'package:rocket_chat_connector_flutter/models/response/response_base.dart';

class QueryResponse extends ResponseBase {
  QueryResponse({
    this.count,
    this.offset,
    this.total,
    success,
  }) : super(success: success);

  int? count;
  int? offset;
  int? total;

  factory QueryResponse.fromMap(Map<String, dynamic> json) => QueryResponse(
    count: json["count"],
    offset: json["offset"],
    total: json["total"],
    success: ResponseBase.fromMap(json).success,
  );

  Map<String, dynamic> toMap() => {
    "count": count,
    "offset": offset,
    "total": total,
  };
}

