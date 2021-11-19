import 'dart:convert';

class ResponseBase {
  bool? success;

  ResponseBase({
    this.success = false,
  });

  factory ResponseBase.fromMap(Map<String, dynamic>? json) => ResponseBase(
    success:  json!['success']
  );

  Map<String, dynamic> toMap() => {
    'success': success,
  };

  @override
  String toString() {
    return jsonEncode(this.toMap());
  }
}
