
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share/share.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as image_util;

import 'platform_depended.dart';

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

Future<String> downloadAndSaveImageFile(String url, String fileName) async {
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

bool isLocalhost() {
  throw UnimplementedError('Unsupported');
}

class WebClipboard {
  addPasteListener(callback) {}
}


Future<String> fileExists(String filename) async {
  String dir = (await getApplicationDocumentsDirectory()).path;

  File file = File('$dir/$filename');
  if (await file.exists())
    return file.path;
  else
    return null;
}

Future<http.Client> downloadFile(String url, String filename, onDone(String path), {onProgress(double percent), bool forceDownload = false}) async {
  var httpClient = http.Client();
  var request = new http.Request('GET', Uri.parse(url));
  var response = httpClient.send(request);
  String dir = (await getApplicationDocumentsDirectory()).path;

  File file = File('$dir/$filename');
  if (await file.exists() && !forceDownload) {
    onDone(FILE_EXISTS);
    return null;
  }

  List<List<int>> chunks = [];
  int downloaded = 0;

  response.asStream().listen((http.StreamedResponse r) {
    r.stream.listen((List<int> chunk) {
      // Display percentage of completion
      double percent = downloaded / r.contentLength;
      if (onProgress != null)
        onProgress(percent);

      chunks.add(chunk);
      downloaded += chunk.length;
    }, onDone: () async {
      // Display percentage of completion
      //print('downloadPercentage: ${downloaded / r.contentLength * 100}');

      // Save the file
      if (downloaded == 0)
        return;
      final Uint8List bytes = Uint8List(r.contentLength);
      int offset = 0;
      for (List<int> chunk in chunks) {
        bytes.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      await file.writeAsBytes(bytes);
      onDone(file.path);
    }, onError: (e) {
      downloaded = 0;
      print('download error=$e');
    });
  });
  return httpClient;
}