// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class TreeStatusChangeMatcher extends ModelMatcher<TreeStatusChange> {
  const TreeStatusChangeMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<TreeStatusChange> get metadata {
    return TreeStatusChange.metadata;
  }

  TreeStatusChangeMatcher hasCreatedOn(Object? matcherOr) {
    return TreeStatusChangeMatcher._(
      _delegate.having((t) => t.createdOn, 'createdOn', matcherOr),
    );
  }

  TreeStatusChangeMatcher hasStatus(Object? matcherOr) {
    return TreeStatusChangeMatcher._(
      _delegate.having((t) => t.status, 'status', matcherOr),
    );
  }

  TreeStatusChangeMatcher hasAuthoredBy(Object? matcherOr) {
    return TreeStatusChangeMatcher._(
      _delegate.having((t) => t.authoredBy, 'authoredBy', matcherOr),
    );
  }

  TreeStatusChangeMatcher hasRepository(Object? matcherOr) {
    return TreeStatusChangeMatcher._(
      _delegate.having((t) => t.repository, 'repository', matcherOr),
    );
  }

  TreeStatusChangeMatcher hasReason(Object? matcherOr) {
    return TreeStatusChangeMatcher._(
      _delegate.having((t) => t.reason, 'reason', matcherOr),
    );
  }
}
