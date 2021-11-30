// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;

// TODO(Yugue): [conductor] add extension method that returns the cherrypick state string,
// https://github.com/flutter/flutter/issues/94387.
extension CherrypickStateExtension on pb.CherrypickState {
  /// Extension method added on [CherrypickState] that returns its equivalent string state.
  ///
  /// In order to use this extended method, one can simply call:
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// import "cherrypick_state.dart";
  /// import 'package:conductor_core/proto.dart' as pb
  ///
  /// final String cherrypickStateStr = pb.CherrypickState.PENDING_WITH_CONFLICT.string();
  /// ```
  /// {@end-tool}
  String string() {
    const Map<pb.CherrypickState, String> cherrypickStates = <pb.CherrypickState, String>{
      pb.CherrypickState.PENDING: 'PENDING',
      pb.CherrypickState.PENDING_WITH_CONFLICT: 'PENDING_WITH_CONFLICT',
      pb.CherrypickState.COMPLETED: 'COMPLETED',
      pb.CherrypickState.ABANDONED: 'ABANDONED',
    };
    return (cherrypickStates[this]!);
  }
}
