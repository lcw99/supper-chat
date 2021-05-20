// To parse this JSON data, do
//
//     final receiptResponse = receiptResponseFromMap(jsonString);

import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/constants/utils.dart';
import 'package:rocket_chat_connector_flutter/models/user.dart';

ReceiptResponse receiptResponseFromMap(String str) => ReceiptResponse.fromMap(json.decode(str));

String receiptResponseToMap(ReceiptResponse data) => json.encode(data.toMap());

class ReceiptResponse {
  ReceiptResponse({
    this.receipts,
    this.success,
  });

  List<Receipt>? receipts;
  bool? success;

  factory ReceiptResponse.fromMap(Map<String, dynamic> json) => ReceiptResponse(
    receipts: json["receipts"] == null ? null : List<Receipt>.from(json["receipts"].map((x) => Receipt.fromMap(x))),
    success: json["success"] == null ? null : json["success"],
  );

  Map<String, dynamic> toMap() => {
    "receipts": receipts == null ? null : List<dynamic>.from(receipts!.map((x) => x.toMap())),
    "success": success == null ? null : success,
  };
}

class Receipt {
  Receipt({
    this.id,
    this.roomId,
    this.userId,
    this.messageId,
    this.ts,
    this.user,
  });

  String? id;
  String? roomId;
  String? userId;
  String? messageId;
  DateTime? ts;
  User? user;

  factory Receipt.fromMap(Map<String, dynamic> json) => Receipt(
    id: json["_id"] == null ? null : json["_id"],
    roomId: json["roomId"] == null ? null : json["roomId"],
    userId: json["userId"] == null ? null : json["userId"],
    messageId: json["messageId"] == null ? null : json["messageId"],
    ts: jsonToDateTime(json["ts"]),
    user: json["user"] == null ? null : User.fromMap(json["user"]),
  );

  Map<String, dynamic> toMap() => {
    "_id": id == null ? null : id,
    "roomId": roomId == null ? null : roomId,
    "userId": userId == null ? null : userId,
    "messageId": messageId == null ? null : messageId,
    "ts": ts == null ? null : ts!.toIso8601String(),
    "user": user == null ? null : user!.toMap(),
  };
}

