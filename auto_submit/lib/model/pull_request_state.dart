// Copyright 2023 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This class holds values for the current states of the pull requests we
/// process with the autosubmit service.
class PullRequestState {
  static String get open => 'open';
  static String get closed => 'closed';
}
