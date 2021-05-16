import 'dart:convert';

class Response {
  bool? success;
  String? body;

  Response({
    this.success = false,
    this.body,
  });

  Response.fromMap(Map<String, dynamic>? json) {
    if (json != null) {
      success = json['success'];
      body = json['body'] != null ? json['body'] : null;
    }
  }

  Map<String, dynamic> toMap() => {
        'success': success,
        'body': body,
      };

  @override
  String toString() {
    return jsonEncode(this.toMap());
  }
}
