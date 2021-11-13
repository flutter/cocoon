// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// A checkbox that toggles between checked and unchecked upon clicking.
///
/// [clickCallback] is called every time the checkbox is clicked.
class CheckboxAsSubstep extends StatelessWidget {
  const CheckboxAsSubstep({
    Key? key,
    required this.isChecked,
    required this.clickCallback,
    required this.substepName,
    this.subtitle,
  }) : super(key: key);

  final bool isChecked;
  final VoidCallback clickCallback;
  final String substepName;
  final Widget? subtitle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: Key(substepName),
      onChanged: (bool? newValue) {
        clickCallback();
      },
      title: Padding(
        padding: const EdgeInsets.only(bottom: 10.0),
        child: Text(substepName),
      ),
      subtitle: subtitle,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.grey,
      value: isChecked,
    );
  }
}
