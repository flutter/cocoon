// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../service/branch_service.dart';

/// Creates the flutter/recipes branch to match a flutter/flutter branch.
///
/// This is used by Google Testing to create release infra whenever a good
/// commit has been found, and is being considered as the branch point to
/// be rolled into Google.
class CreateBranch extends ApiRequestHandler<Body> {
  const CreateBranch({
    required this.branchService,
    required super.config,
    required super.authenticationProvider,
  });

  final BranchService branchService;

  static const String branchParam = 'branch';
  // Intentionally kept at 'engine' as there may be scripts out there.
  static const String engineShaParam = 'engine';

  @override
  Future<Body> get() async {
    checkRequiredQueryParameters(<String>[branchParam, engineShaParam]);
    final String branch = request!.uri.queryParameters[branchParam]!;
    final String engineSha = request!.uri.queryParameters[engineShaParam]!;

    await branchService.branchFlutterRecipes(branch, engineSha);

    return Body.empty;
  }
}
