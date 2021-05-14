
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image_util;

Object shareFile(String url, Map<String, String> header) async {
  DefaultCacheManager manager = new DefaultCacheManager();
  File f = await manager.getSingleFile(url, headers: header);
  Share.shareFiles([f.path]);
  return null;
}

Widget pickedImage(String path, {double imageWidth, double imageHeight, cacheWidth}) {
  return Image.file(File(path),
    fit: BoxFit.contain,
    width: imageWidth,
    height: imageHeight,
    cacheWidth: cacheWidth,
  );
}

Future<String> downloadAndSaveFile(String url, String fileName) async {
  final Directory directory = await getTemporaryDirectory();
  final String filePath = '${directory.path}/$fileName';
  final http.Response response = await http.get(Uri.parse(url));
  final File file = File(filePath);

  var image = image_util.decodeImage(response.bodyBytes);
  var smallImage = image_util.copyResize(image, width: 40, height: 40);
  var bytes = image_util.encodePng(smallImage);
  await file.writeAsBytes(bytes);

  return filePath;
}

