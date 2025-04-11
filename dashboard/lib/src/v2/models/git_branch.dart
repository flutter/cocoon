// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// Represents a branch on a Git repository.
@immutable
final class GitBranch {
  GitBranch.from(this.name, {this.alias});

  /// The branch name.
  final String name;

  /// A named alias for the branch, sometimes referred to as a "channel".
  final String? alias;

  @override
  bool operator ==(Object other) {
    return other is GitBranch && name == other.name;
  }

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() {
    if (alias case final alias?) {
      return 'GitBranch.from($name, alias: $alias)';
    }
    return 'GitBranch.from($name)';
  }
}
