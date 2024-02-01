// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:auto_submit/service/config.dart';
import 'package:github/github.dart' as github;

abstract class RevertMethod {
  // Allows substitution of the method of creating the revert request.
  Future<Object?> createRevert(Config config, String initiatingAuthor, String reasonForRevert, github.PullRequest pullRequest);
}
