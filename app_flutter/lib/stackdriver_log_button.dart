// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:cocoon_service/protos.dart' show Task;

class StackdriverLogButton extends StatefulWidget {
  const StackdriverLogButton(this.task);

  final Task task;

  @override
  _StackdriverLogButtonState createState() => _StackdriverLogButtonState();
}

class _StackdriverLogButtonState extends State<StackdriverLogButton> {
  int attemptNumberValue = 1;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: attemptNumberValue,
      icon: Icon(Icons.receipt),
      iconSize: 24,
      elevation: 16,
      style: TextStyle(color: Colors.deepPurple),
      underline: Container(
        height: 2,
        color: Colors.deepPurpleAccent,
      ),
      onChanged: (int newValue) {
        setState(() {
          attemptNumberValue = newValue;
        });
      },
      items: List<int>.generate(widget.task.attempts, (int i) => i)
          .map<DropdownMenuItem<int>>(
            (int value) => DropdownMenuItem<int>(
              value: value,
              child: Text('Attempt $value'),
            ),
          )
          .toList(),
    );
  }
}
