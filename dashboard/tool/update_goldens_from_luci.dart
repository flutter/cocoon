// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io' as io;

void main(List<String> args) async {
  if (args.length != 1) {
    io.stderr.writeln(
      'Usage: dart run tool/update_goldens_from_luci.dart <flutter/cocoon PR#>',
    );
    io.exitCode = 1;
    return;
  }
}
