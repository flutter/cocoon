// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Function that prompts a snackbar at the bottom of the page.
///
/// Clicking on [Ok] will close the snackbar.
/// The snackbar will stay displayed for 2 minutes unless [Ok] is clicked.
void snackbarPrompt({
  required BuildContext context,
  required String msg,
}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: SelectableText(msg, style: Theme.of(context).textTheme.subtitle1!.copyWith(color: Colors.red)),
      duration: const Duration(minutes: 2),
      action: SnackBarAction(
        label: 'Ok',
        onPressed: () {},
      ),
    ),
  );
}
