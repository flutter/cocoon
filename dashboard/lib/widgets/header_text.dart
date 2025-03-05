// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Text header.
///
/// Displays the given text using font headline4.
class HeaderText extends StatelessWidget {
  const HeaderText(
    this.text, {
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: Theme.of(context).textTheme.headlineMedium,
        textAlign: TextAlign.center);
  }
}
