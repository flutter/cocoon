// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';

@immutable
class GetBranches extends RequestHandler<Body> {
  const GetBranches(
    Config config,
  ) : super(config: config);

  @override
  Future<Body> get() async {
    final List<String> branches = await config.flutterBranches;

    return Body.forJson(<String, List<String>>{'Branches': branches});
  }
}
