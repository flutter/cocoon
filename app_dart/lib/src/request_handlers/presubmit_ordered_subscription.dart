// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import '../../cocoon_service.dart';

/// An endpoint for listening to ordered LUCI status updates for scheduled builds
/// from the PubSub subscription [ordered-presubmit-sub].
///
/// Messages in this subscription are delivered sequentially by ordering key
/// and are processed directly using the shared presubmit LUCI logic in
/// [PresubmitSubscription.post].
@immutable
final class PresubmitOrderedSubscription extends PresubmitSubscription {
  /// Creates an endpoint for listening to ordered LUCI status updates.
  const PresubmitOrderedSubscription({
    required super.cache,
    required super.config,
    required super.luciBuildService,
    required super.githubChecksService,
    required super.ciYamlFetcher,
    required super.scheduler,
    required super.firestore,
    super.authProvider,
  }) : super(subscriptionName: 'ordered-presubmit-sub');
}
