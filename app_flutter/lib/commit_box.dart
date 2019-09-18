// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Displays Git commit information.
class CommitBox extends StatefulWidget {
  // TODO(chillers): convert to use commit model
  const CommitBox(
      {Key key,
      @required this.message,
      @required this.avatarUrl,
      @required this.author,
      @required this.sha})
      : super(key: key);

  /// Commit message that summarizes the change made.
  final String message;

  /// Image URL to the avatar of the author of this commit.
  final String avatarUrl;

  /// The person that authored this commit.
  final String author;

  /// The unique identifier for the commit in this repository
  final String sha;

  @override
  _CommitBoxState createState() => _CommitBoxState();
}

class _CommitBoxState extends State<CommitBox> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(1.0),
      child: Image.network(
        widget.avatarUrl,
        height: 40,
      ),
    );
  }
}
