// Copyright 2022 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// The type of the change in the pull request we have processed.
enum PullRequestChangeType {
  /// Merge is any submitted pull request change that does not undo previous changes.
  change,

  /// Revert is specifically for undoing changes.
  revert,
}

/// Values representing the current states of a pull requests we process with
/// the autosubmit service.
enum PullRequestState { open, closed }
