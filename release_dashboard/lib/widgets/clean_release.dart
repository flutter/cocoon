// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'common/dialog_prompt.dart';

/// Button to clean the current release.
class CleanRelease extends StatelessWidget {
  const CleanRelease({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 40, 0),
      child: IconButton(
        key: const Key('conductorClean'),
        icon: const Icon(Icons.delete),
        onPressed: () {
          dialogPrompt(
            context: context,
            title: 'Are you sure you want to clean up the current release?',
            content: 'This will abort and delete a work in progress release. This process is not revertible!',
            leftOptionTitle: 'Yes',
            rightOptionTitle: 'No',
          );
        },
        tooltip: 'Clean up the current release.',
      ),
    );
  }
}
