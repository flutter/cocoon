// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/approver_service.dart';
import 'package:github/github.dart';

class FakeApproverService extends ApproverService {
  FakeApproverService(super.config);

  @override
  Future<void> autoApproval(PullRequest pullRequest) async {
    // no op
  }

  @override
  Future<void> revertApproval(PullRequest pullRequest) async {
    // no op
  }
}
