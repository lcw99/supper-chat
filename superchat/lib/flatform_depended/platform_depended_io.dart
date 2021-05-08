
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:share/share.dart';

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