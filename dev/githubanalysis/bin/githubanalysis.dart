// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' show exit;

import 'package:githubanalysis/main.dart' as lib show main;

void main(final List<String> arguments) async {
  exit(await lib.main(arguments));
}
