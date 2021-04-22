import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class InputFileDescription extends StatelessWidget {
  InputFileDescription({Key key, this.file}) : super(key: key);
  final File file;

  final TextEditingController _teController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('Description'),
      ),
      body:
      Column(children: <Widget>[
      FileViewer(file: file),
      Container(
          child:
          Row(children: <Widget>[
            Expanded(child:
            Form(
              child: TextFormField(
                controller: _teController,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(hintText: 'Descriptions', contentPadding: EdgeInsets.all(10)),
              ),
            )),
            InkWell(
              onTap: () {
                String ret = '';
                if (_teController.text.isNotEmpty)
                  ret = _teController.text;
                Navigator.pop(context, ret);
              },
              child: Icon(Icons.check, color: Colors.blueAccent,),
            ),
          ])
      )
    ])));
  }

}

class FileViewer extends StatelessWidget {
  const FileViewer({Key key, this.file}) : super(key: key);
  final File file;

  @override
  Widget build(BuildContext context) {
    MediaType mt = MediaType.parse(lookupMimeType(file.path));
    switch (mt.type) {
      case 'image':
        return Image.file(file);
        break;
      case 'audio':
      case 'text':
      case 'video':
      default:
        return Text(file.path);
    }
  }
}

