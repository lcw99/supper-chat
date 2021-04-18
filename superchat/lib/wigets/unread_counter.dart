import 'package:flutter/material.dart';

class UnreadCounter extends StatelessWidget {
  final int unreadCount;

  const UnreadCounter({Key key, this.unreadCount}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    String unreadCountStr = '';
    if (unreadCount > 0)
      unreadCountStr = unreadCount.toString();
    return unreadCountStr != '' ? Container(
        alignment: Alignment.center,
        width: 20,
        height: 20,
        child: Text(unreadCountStr, style: TextStyle(color: Colors.white, fontSize: 12)),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blue,)
    ) : Container(width: 1, height: 1,);
  }
}
