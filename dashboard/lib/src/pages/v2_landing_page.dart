// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

final class V2LandingPage extends StatefulWidget {
  const V2LandingPage([this.repoOwner, this.repoName]);

  final String? repoOwner;
  final String? repoName;

  @override
  State<StatefulWidget> createState() => _V2LandingState();
}

final class _V2LandingState extends State<V2LandingPage> {
  String? repoOwner;
  String? repoName;

  @override
  void initState() {
    repoOwner = widget.repoOwner;
    repoName = widget.repoName;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text('$repoOwner/$repoName')),
    );
  }
}
