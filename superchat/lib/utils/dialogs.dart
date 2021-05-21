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

showSimpleAlertDialog(context, String title, String content, void onOk(), { void onCancel() }) async {
  var buttons = [
    TextButton(
      child: Text("OK"),
      onPressed: () {
        onOk();
      },
    ),
  ];
  if (onCancel != null) {
    buttons.insert(0, TextButton(
        child: Text("Cancel"),
        onPressed: () {
          onCancel();
        },
      ),
    );
  }
  return await showDialog(
      context: context,
      builder: (BuildContext c) {
        return AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: buttons,
        );
      }
  );
}
