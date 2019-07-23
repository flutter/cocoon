// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../model/agent.dart';

/// Class that represents an authenticated request having been made, and any
/// attached metadata to that request.
@immutable
class RequestContext {
  /// Creates a new [RequestContext].
  const RequestContext({this.agent});

  /// The agent making the request.
  ///
  /// This will be null if the request is not being made by an agent. Even if
  /// this property is null, the request has been authenticated (by virtue of
  /// the request context having been created).
  final Agent agent;
}
