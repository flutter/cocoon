// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_web/material.dart';
import 'package:flutter_web_ui/ui.dart' as ui;

import 'package:cocoon/repository/repository.dart' show RepositoryDashboardApp;

Future<void> main() async {
  await ui.webOnlyInitializePlatform();
  runApp(RepositoryDashboardApp());
}
