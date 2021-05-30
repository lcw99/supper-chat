import 'package:flutter/material.dart';
import 'package:flutter_dropzone/flutter_dropzone.dart';

Object shareFile(String url, Map<String, String> header) {
  throw UnimplementedError('Unsupported');
}

Widget pickedImage(String path, {double imageWidth, double imageHeight, cacheWidth}) {
  throw UnimplementedError('Unsupported');
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
  throw UnimplementedError('Unsupported');
}

class WebClipboard {
  addPasteListener(callback) {}
}
