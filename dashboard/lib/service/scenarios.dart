// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Definitions of data scenarios for development and testing.
enum Scenario {
  /// Realistic distribution of task statuses.
  realistic,

  /// All tasks succeeded for all commits.
  allGreen,

  /// All non-bringup tasks failed for the most recent commit.
  redTree,

  /// Many commits with many tasks, to test performance.
  highLoad,

  /// No commits found.
  empty,
}
