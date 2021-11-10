// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

typedef ClickCallback = void Function(String substepName);

/// A checkbox that toggles between checked and unchecked upon clicking.
///
/// [clickCallback] is called every time the checkbox is clicked.
class CheckboxAsSubstep extends StatelessWidget {
  const CheckboxAsSubstep({
    Key? key,
    required this.isEachSubstepChecked,
    required this.clickCallback,
    required this.substepName,
    this.subtitle,
  }) : super(key: key);

  final Map<String, bool> isEachSubstepChecked;
  final ClickCallback clickCallback;
  final String substepName;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      key: Key(substepName),
      onChanged: (bool? newValue) {
        clickCallback(substepName);
      },
      title: Text(substepName),
      subtitle: subtitle != null ? SelectableText(subtitle!) : null,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.grey,
      value: isEachSubstepChecked[substepName],
    );
  }
}
