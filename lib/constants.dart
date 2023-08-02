import 'package:flutter/material.dart';

const defaultPadding = 16.0;

void showCustomSnackBar({
  required BuildContext context,
  Duration? duration,
  required String title,
  required String snackBarActionLabel,
  required VoidCallback onSnackBarActionClicked,
}) {
  var snackBar = SnackBar(
    content: Text(title),
    duration: duration ?? Duration(seconds: 4),
    action: SnackBarAction(
      label: 'Desfazer',
      onPressed: onSnackBarActionClicked,
    ),
  );

  ScaffoldMessenger.of(context).removeCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
