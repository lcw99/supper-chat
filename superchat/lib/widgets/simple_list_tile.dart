import 'package:flutter/material.dart';

typedef void ListTileCallBack();
class SimpleListTile extends StatefulWidget {
  const SimpleListTile({Key key, this.leading, this.title, this.subtitle, this.trailing, this.onTap}) : super(key: key);

  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final ListTileCallBack onTap;

  @override
  _SimpleListTileState createState() => _SimpleListTileState();
}

class _SimpleListTileState extends State<SimpleListTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(child:
    Row(children: [
      SizedBox(child: widget.leading, width: 40, height: 100,),
      Expanded(child: Column(children: [
        Container(child: widget.title, height: 20,),
        Container(child: widget.subtitle,),
      ]),),
      SizedBox(child: widget.trailing, width: 30, height: 100,),
    ], crossAxisAlignment: CrossAxisAlignment.end,),
    onTap: () => widget.onTap());
  }
}
