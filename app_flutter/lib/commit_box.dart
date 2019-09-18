// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Displays Git commit information.
class CommitBox extends StatelessWidget {
  // TODO(chillers): convert to use commit model
  const CommitBox({
    Key key,
    @required this.message,
    @required this.avatarUrl,
  }) : super(key: key);

  /// Commit message that summarizes the change made.
  final String message;

  /// Image URL to the avatar of the author of this commit.
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    // TODO(chillers): add overlay to view more information
    return Container(
      margin: const EdgeInsets.all(1.0),
      child: Image.network(
        avatarUrl,
        height: 40,
      ),
    );
  }
}
