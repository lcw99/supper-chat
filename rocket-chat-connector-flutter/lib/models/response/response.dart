import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/response/response_base.dart';

class Response extends ResponseBase {
  String? body;

  Response({
    success,
    this.body,
  }) : super(success: success);

  Response.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      body = json['body'] != null ? json['body'] : null;
    }
  }

  Map<String, dynamic> toMap() => {
        'body': body,
      };
}
