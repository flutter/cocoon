// Copyright (c) 2020 The Flutter Authors All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

import 'repository.dart';

void main() {
  runApp(RepositoryDashboard());
}

class RepositoryDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: RepositoryDashboardApp(),
    );
  }
}
