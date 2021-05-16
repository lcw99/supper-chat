import 'package:flutter/material.dart';

Future<dynamic> showDialogWithWidget(context, Widget content, double height, {bool alertDialog = true}) async {
  dynamic response = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return alertDialog ? AlertDialog(insetPadding: EdgeInsets.all(15),
        content: SizedBox(height: height, width: MediaQuery.of(context).size.width,
          child: content
      )):
      Dialog(insetPadding: EdgeInsets.all(15),
          child: SizedBox(height: height, width: MediaQuery.of(context).size.width,
              child: content
          ));
    }
  );
  return response;
}