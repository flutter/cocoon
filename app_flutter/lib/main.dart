// Copyright (c) 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'build_dashboard.dart';

void main() {
  if (kIsWeb) {
    /// This application is displayed on a TV that is hard to reach.
    /// Refreshing this page ensures the TV stays relatively up to date without
    /// anyone having to get on a ladder to use the TV as a computer.
    Timer.periodic(
        const Duration(days: 1), (_) => html.window.location.reload());
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Build Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BuildDashboardPage(),
    );
  }
}
