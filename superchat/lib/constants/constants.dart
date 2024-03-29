import 'package:flutter/material.dart';

final Uri serverUri = Uri.parse("https://rc.plan4.house");
final String webSocketUrl = "wss://rc.plan4.house/websocket";
const double MESSAGE_FONT_SIZE = 16;
const double USERNAME_FONT_SIZE = 12;
const double DEFAULT_AVATAR_SIZE = 40;
const String readCountEmoji = ':red_circle:';
final Color chatBackgroundColor = Color(0xffb4c8db);
final Color chatMyMessageColor = Color(0xffffeb31);
final Color chatUnreadCountColor = Color(0xfff9ea4c);
final Color chatChatTimeColor = Color(0xff5a6673);
final Color displayNameColor = Color(0xff5a6673);

final Widget rotatedPin = Transform.rotate(child: Icon(Icons.push_pin_outlined, size: 12, color: Colors.redAccent), angle: 45 * 3.14 / 180,);

