import 'package:universal_io/io.dart';
import 'dart:typed_data';

import 'package:extended_image/extended_image.dart' as ei;
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:ss_image_editor/common/image_picker/image_picker.dart';
import 'package:ss_image_editor/ss_image_editor.dart';

class ImageFileData {
  Uint8List imageData;
  String description;
  ImageFileData(this.imageData, this.description);
}

class ImageFileDescription extends StatefulWidget {
  final File file;
  final Uint8List imageData;
  ImageFileDescription({Key key, this.file, this.imageData}) : super(key: key);

  @override
  _ImageFileDescriptionState createState() => _ImageFileDescriptionState();
}

class _ImageFileDescriptionState extends State<ImageFileDescription> {
  final TextEditingController _teController = TextEditingController();

  Uint8List _memoryImage;
  bool edited;

  @override
  void initState() {
    if (widget.file != null)
      _memoryImage = widget.file.readAsBytesSync();
    if (widget.imageData != null)
      _memoryImage = widget.imageData;
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
              retData = ImageFileData(_memoryImage, desc);
              Navigator.pop(context, retData);
            },
          ),
        ],
      ),
      body:
      SingleChildScrollView(child:
      Column(children: <Widget>[
      ei.ExtendedImage.memory(_memoryImage),
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

