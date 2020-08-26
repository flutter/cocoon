// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cocoon_service/src/service/luci.dart';
import 'package:github/github.dart';
import 'package:meta/meta.dart';

import '../datastore/cocoon_config.dart';
import '../request_handling/body.dart';
import '../request_handling/request_handler.dart';

/// Returns  repo [config.flutterSlug] branches that match pre-defined
/// branch regular expressions.
@immutable
class GetBranches extends RequestHandler<Body> {
  const GetBranches(
    Config config,
  ) : super(config: config);

  @override
  Future<Body> get() async {
    //final List<String> branches = await config.flutterBranches;
    final List<LuciBuilder> branches = await config.luciTryBuilders('14da93959b5c8063ae01b0e51a3847aec75d986a', RepositorySlug('flutter', 'flutter'), 64609);

    return Body.forJson(<String, List<LuciBuilder>>{'Branches': branches});
  }
}
