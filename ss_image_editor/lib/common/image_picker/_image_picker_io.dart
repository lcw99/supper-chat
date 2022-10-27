import 'dart:async';
import 'package:universal_io/io.dart';
import 'dart:typed_data';

//import 'package:image_picker/image_picker.dart' as picker;
import 'package:flutter/cupertino.dart';
import 'package:photo_manager/photo_manager.dart';

/*
Future<dynamic?> pickImage(BuildContext context, {bool fileResult = false}) async {
  List<AssetEntity> assets = <AssetEntity>[];
  final List<AssetEntity>? result = await AssetPicker.pickAssets(
    context,
    maxAssets: 1,
    pathThumbSize: 84,
    gridCount: 3,
    pageSize: 300,
    selectedAssets: assets,
    requestType: RequestType.image,
    textDelegate: PickerTextDelegate(),
  );
  if (result != null) {
    assets = List<AssetEntity>.from(result);
    if (fileResult)
      return assets.first.file;
    else
      return assets.first.originBytes;
  }
  return null;
  // final File file =

  //     await picker.ImagePicker.pickImage(source: picker.ImageSource.gallery);
  // return file.readAsBytes();
}
*/

class ImageSaver {
  static Future<String?> save(String name, Uint8List fileData) async {
    final AssetEntity? imageEntity =
        await PhotoManager.editor.saveImage(fileData, title: "");
    final File? file = await imageEntity?.file;
    return file?.path;
  }
}


/*
class PickerTextDelegate implements AssetsPickerTextDelegate {
  factory PickerTextDelegate() => _instance;

  PickerTextDelegate._internal();

  static final PickerTextDelegate _instance = PickerTextDelegate._internal();

  @override
  String confirm = 'OK';

  @override
  String cancel = 'Cancel';

  @override
  String edit = 'Edit';

  @override
  String gifIndicator = 'GIF';

  @override
  String heicNotSupported = 'not support HEIC yet';

  @override
  String loadFailed = 'load failed';

  @override
  String original = 'Original';

  @override
  String preview = 'Preview';

  @override
  String select = 'Select';

  @override
  String unSupportedAssetType = 'not support yet';

  @override
  String durationIndicatorBuilder(Duration duration) {
    const String separator = ':';
    final String minute = duration.inMinutes.toString().padLeft(2, '0');
    final String second =
        ((duration - Duration(minutes: duration.inMinutes)).inSeconds)
            .toString()
            .padLeft(2, '0');
    return '$minute$separator$second';
  }
}
*/
