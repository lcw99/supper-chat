import 'package:flutter/material.dart';
import 'dart:html' as html;

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
  return html.window.location.hostname.startsWith('localhost');
}