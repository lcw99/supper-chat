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

Future<String> downloadAndSaveImageFile(String url, String fileName) async {
  throw UnimplementedError('Unsupported');
}

Future<String> fileExists(String filename) async {
  throw UnimplementedError('Unsupported');
}

void downloadFile(String url, String filename, onDone(String path), {onProgress(double percent), bool forceDownload = false}) async {
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
    document.removeEventListener('paste', pasteAuto, false);
    _singleton._callback = callback;
    document.addEventListener('paste', pasteAuto, false);
  }

  pasteAuto(Event ee) async {
    ClipboardEvent e = ee;
    if (e.clipboardData != null) {
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