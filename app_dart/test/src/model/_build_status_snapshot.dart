// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class BuildStatusSnapshotMatcher
    extends ModelMatcher<BuildStatusSnapshot> {
  const BuildStatusSnapshotMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<BuildStatusSnapshot> get metadata {
    return BuildStatusSnapshot.metadata;
  }

  BuildStatusSnapshotMatcher hasStatus(Object? matcherOr) {
    return BuildStatusSnapshotMatcher._(
      _delegate.having((status) => status.status, 'status', matcherOr),
    );
  }

  BuildStatusSnapshotMatcher hasCreatedOn(Object? matcherOr) {
    return BuildStatusSnapshotMatcher._(
      _delegate.having((status) => status.createdOn, 'createdOn', matcherOr),
    );
  }

  BuildStatusSnapshotMatcher hasFailingTasks(Object? matcherOr) {
    return BuildStatusSnapshotMatcher._(
      _delegate.having(
        (status) => status.failingTasks,
        'failingTasks',
        matcherOr,
      ),
    );
  }
}
