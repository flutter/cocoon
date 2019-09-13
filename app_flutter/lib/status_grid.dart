// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'result_box.dart';

class StatusGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    /// SliverGrid only renders the cells that are visible to the screen. Additionally, it offers support for scrolling.
    return CustomScrollView(
      slivers: <Widget>[
        SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 50.0,
            mainAxisSpacing: 1.0,
            crossAxisSpacing: 1.0,
          ),
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int index) {
              // TODO(chillers): use a data source
              String randomMessage =
                  ResultBox.resultColor.keys.toList()[4 * (index & 1)];
              return ResultBox(message: randomMessage);
            },
            childCount: 2000,
          ),
        ),
      ],
    );
  }
}
