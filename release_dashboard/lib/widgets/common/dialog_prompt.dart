// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Function that prompts an alert to the current window and forces the user to choose between two options.
Future<String?> dialogPrompt({
  required BuildContext context,
  required Widget title,
  required Widget? content,
  required String leftButtonTitle,
  required String rightButtonTitle,
  VoidCallback? leftButtonCallback,
  VoidCallback? rightButtonCallback,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: title,
      content: content,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            if (leftButtonCallback != null) leftButtonCallback();
            Navigator.pop(context, leftButtonTitle);
          },
          child: Text(leftButtonTitle),
        ),
        TextButton(
          onPressed: () {
            if (rightButtonCallback != null) rightButtonCallback();
            Navigator.pop(context, rightButtonTitle);
          },
          child: Text(rightButtonTitle),
        ),
      ],
    ),
  );
}

/// Widget that prompts an alert to the current window and forces the user to choose between two options.
///
/// User also has to input [confirmationString] as an extra layer of validation.
/// The right button becomes enabled when [_userInput] matches [confirmationString], otherwise it is disabled.
class DialogPromptInputConfirm extends StatefulWidget {
  const DialogPromptInputConfirm({
    required this.title,
    required this.content,
    required this.leftButtonTitle,
    required this.rightButtonTitle,
    required this.confirmationString,
    this.leftButtonCallback,
    this.rightButtonCallback,
    Key? key,
  }) : super(key: key);

  final Widget title;
  final Widget? content;
  final String leftButtonTitle;
  final String rightButtonTitle;
  final String confirmationString;
  final VoidCallback? leftButtonCallback;
  final VoidCallback? rightButtonCallback;

  @override
  State<DialogPromptInputConfirm> createState() => _DialogPromptInputConfirmState();
}

class _DialogPromptInputConfirmState extends State<DialogPromptInputConfirm> {
  String _userInput = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: widget.title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.content != null) widget.content!,
          TextFormField(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(
              labelText: "Please type '${widget.confirmationString}' to confirm",
            ),
            onChanged: (String data) {
              setState(() {
                _userInput = data;
              });
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          key: Key(widget.leftButtonTitle),
          onPressed: () {
            if (widget.leftButtonCallback != null) widget.leftButtonCallback!();
            Navigator.pop(context, widget.leftButtonTitle);
          },
          child: Text(widget.leftButtonTitle),
        ),
        TextButton(
          key: Key(widget.rightButtonTitle),
          onPressed: _userInput == widget.confirmationString
              ? () {
                  if (widget.rightButtonCallback != null) widget.rightButtonCallback!();
                  Navigator.pop(context, widget.rightButtonTitle);
                }
              : null,
          child: Text(widget.rightButtonTitle),
        ),
      ],
    );
  }
}
