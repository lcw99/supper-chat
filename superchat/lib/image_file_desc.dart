import 'dart:io';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ss_image_editor/common/image_picker/image_picker.dart';
import 'package:ss_image_editor/ss_image_editor.dart';

class ImageFileData {
  String filePath;
  String description;
  ImageFileData(this.filePath, this.description);
}

class ImageFileDescription extends StatefulWidget {
  ImageFileDescription({Key key, this.file}) : super(key: key);
  final File file;

  @override
  _ImageFileDescriptionState createState() => _ImageFileDescriptionState();
}

class _ImageFileDescriptionState extends State<ImageFileDescription> {
  final TextEditingController _teController = TextEditingController();

  Uint8List _memoryImage;
  bool edited;

  @override
  void initState() {
    _memoryImage = widget.file.readAsBytesSync();
    edited = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, null);
        return false;
      },
      child: Scaffold(
/*
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox()
      ),
*/
      appBar: AppBar(
        title: Text('Description'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              if (_memoryImage != null) {
                var imageData = await Navigator.push(context, MaterialPageRoute(builder: (context) => SSImageEditor(memoryImage: _memoryImage)));
                if (imageData != null) {
                  edited = true;
                  setState(() {
                    _memoryImage = imageData;
                  });
                }
              } else {
                print('No image selected.');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.done),
            onPressed: () async {
              String desc = '';
              if (_teController.text.isNotEmpty)
                desc = _teController.text;
              ImageFileData retData;
              if (edited) {
                final String imageFilePath = await ImageSaver.save(tempImageFileName, _memoryImage);
                retData = ImageFileData(imageFilePath, desc);
              } else {
                retData = ImageFileData(widget.file.path, desc);
              }
              Navigator.pop(context, retData);
            },
          ),
        ],
      ),
      body:
      SingleChildScrollView(child:
      Column(children: <Widget>[
      ExtendedImage.memory(_memoryImage),
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
          ])
      )
    ]))));
  }
}

