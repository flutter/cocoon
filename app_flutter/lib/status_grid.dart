// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'result_box.dart';

class StatusGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: 100,
      gridDelegate:
          SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 20),
      itemBuilder: (BuildContext context, int index) {
        String randomMessage = ResultBox.resultColor.keys
            .toList()[index % ResultBox.resultColor.keys.length];
        return ResultBox(message: randomMessage);
      },
    );
  }
}
