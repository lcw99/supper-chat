// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:flutter/material.dart';

typedef void ClipboardCallback(dynamic blob);

Object shareFile(String url, Map<String, String> header) {
  return null;
}

Widget pickedImage(String path, {double imageWidth, double imageHeight, cacheWidth}) {
  return Image.network(path, width: imageWidth, height: imageHeight, cacheWidth: cacheWidth,);
}

Future<String> downloadAndSaveFile(String url, String fileName) async {
  throw UnimplementedError('Unsupported');
}

bool isLocalhost() {
  return window.location.hostname.startsWith('localhost');
}

class WebClipboard {
  ClipboardCallback _callback;
  static final WebClipboard _singleton = WebClipboard._internal();
  factory WebClipboard() {
    return _singleton;
  }

  WebClipboard._internal();

  addPasteListener(ClipboardCallback callback) {
    print('##### addPasteListener @@@@@####');
    document.removeEventListener('paste', pasteAuto, false);
    _singleton._callback = callback;
    document.addEventListener('paste', pasteAuto, false);
  }

  pasteAuto(Event ee) async {
    ClipboardEvent e = ee;
    if (e.clipboardData != null) {
      print('@@@@@@@@@@@@@@@@@ clipboard event');
      var items = e.clipboardData.items;
      if (items == null) return;

      //access data directly
      var blob;
      for (var i = 0; i < items.length; i++) {
        if (items[i].type.indexOf("image") != -1) {
          blob = items[i].getAsFile();
          break;
        }
      }
      if (blob != null) {
        _singleton._callback(blob);
        e.preventDefault();
      }
    }
  }
}