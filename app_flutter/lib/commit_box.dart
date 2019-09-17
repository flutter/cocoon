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

  final String message;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Image.network(
          avatarUrl,
          height: 40,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(message),
        ),
      ],
    );
  }
}
