// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../request_handling/api_request_handler.dart';
import '../request_handling/body.dart';
import '../service/branch_service.dart';

/// Creates the flutter/recipes branch to match a flutter/flutter branch.
///
/// This is intended for oncall use as a fallback when creating recipe branches.
class CreateBranch extends ApiRequestHandler<Body> {
  const CreateBranch({
    required this.branchService,
    required super.config,
    required super.authenticationProvider,
  });

  final BranchService branchService;

  static const String branchParam = 'branch';

  @override
  Future<Body> get() async {
    checkRequiredQueryParameters(<String>[branchParam]);
    final String branch = request!.uri.queryParameters[branchParam]!;

    await branchService.branchFlutterRecipes(branch);

    return Body.empty;
  }
}
