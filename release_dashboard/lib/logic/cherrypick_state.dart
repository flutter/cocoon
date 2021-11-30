// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:conductor_core/proto.dart' as pb;

const Map<pb.CherrypickState, String> cherrypickStates = <pb.CherrypickState, String>{
  pb.CherrypickState.PENDING: 'PENDING',
  pb.CherrypickState.PENDING_WITH_CONFLICT: 'PENDING_WITH_CONFLICT',
  pb.CherrypickState.COMPLETED: 'COMPLETED',
  pb.CherrypickState.ABANDONED: 'ABANDONED',
};

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
  /// final String cherrypickStateStr = pb.CherrypickState.PENDING_WITH_CONFLICT.cherrypickStateStr();
  /// ```
  /// {@end-tool}
  String cherrypickStateStr() {
    return (cherrypickStates[this]!);
  }
}
