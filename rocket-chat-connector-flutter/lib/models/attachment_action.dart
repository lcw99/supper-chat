import 'dart:convert';

class AttachmentAction {
  String? text;
  String? msg;
  String? type;
  bool? msgInChatWindow;

  AttachmentAction({this.text, this.msg, this.type, this.msgInChatWindow});

  AttachmentAction.fromMap(Map<String, dynamic> json) {
    text = json['text'];
    msg = json['msg'];
    type = json['type'];
    msgInChatWindow = json['msg_in_chat_window'];
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['text'] = this.text;
    data['msg'] = this.msg;
    data['type'] = this.type;
    data['msg_in_chat_window'] = this.msgInChatWindow;
    return data;
  }

  @override
  String toString() {
    return jsonEncode(this.toMap());
  }

}