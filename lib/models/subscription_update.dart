import 'dart:convert';

import 'package:rocket_chat_connector_flutter/models/subscription.dart';

class SubscriptionUpdate {
  List<Subscription>? update;
  List<Subscription>? remove;
  bool? success;

  SubscriptionUpdate({
    this.update,
    this.remove,
    this.success,
  });

  factory SubscriptionUpdate.fromMap(Map<String, dynamic> json) => SubscriptionUpdate(
    update: List<Subscription>.from(json["update"].map((x) => Subscription.fromMap(x))),
    remove: List<Subscription>.from(json["remove"].map((x) => Subscription.fromMap(x))),
    success: json["success"],
  );

  Map<String, dynamic> toMap() => {
    "update": List<Subscription>.from(update!.map((x) => x.toMap())),
    "remove": List<Subscription>.from(remove!.map((x) => x.toMap())),
    "success": success,
  };

  @override
  String toString() {
    return 'Subscription{update: $update, remove: $remove, success: $success}';
  }
}
