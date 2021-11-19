import 'package:flutter/material.dart';

typedef void ListTileCallBack();
class SimpleListTile extends StatefulWidget {
  const SimpleListTile({Key key, this.leading, this.title, this.subtitle, this.trailing, this.onTap,
    this.leadingWidth = 50, this.leadingHeight = 50, this.trailingWidth = 0, this.trailingHeight = 0,
    this.horizontalTitleGap = 0, this.selected, this.selectedTileColor, this.horizontalPadding = 20
  }) : super(key: key);

  final Widget leading;
  final Widget title;
  final Widget subtitle;
  final Widget trailing;
  final ListTileCallBack onTap;
  final double leadingWidth;
  final double leadingHeight;
  final double trailingWidth;
  final double trailingHeight;
  final double horizontalTitleGap;
  final double horizontalPadding;
  final Color selectedTileColor;
  final bool selected;

  @override
  _SimpleListTileState createState() => _SimpleListTileState();
}

class _SimpleListTileState extends State<SimpleListTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onTap(),
      child: Container(
      padding: EdgeInsets.only(left: widget.horizontalPadding, top: 0, right: widget.horizontalPadding, bottom: 0),
      color: widget.selected ? widget.selectedTileColor : Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(child: widget.leading, width: widget.leadingWidth, height: widget.leadingHeight,),
          SizedBox(width: widget.horizontalTitleGap,),
          Expanded(child: Column(children: [
            Container(child: widget.title, ),
            Container(child: widget.subtitle,),
          ]),),
          widget.trailing == null ? SizedBox() :
          Row(
            children: [
            SizedBox(width: widget.horizontalTitleGap,),
            SizedBox(child: widget.trailing, width: widget.trailingWidth, height: widget.trailingHeight,),
          ],)
        ]),
    ));
  }
}
