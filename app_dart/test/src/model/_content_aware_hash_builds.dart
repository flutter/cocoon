// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class ContentAwareHashBuildsMatcher
    extends ModelMatcher<ContentAwareHashBuilds> {
  const ContentAwareHashBuildsMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<ContentAwareHashBuilds> get metadata {
    return ContentAwareHashBuilds.metadata;
  }

  ContentAwareHashBuildsMatcher hasStatus(Object? matcherOr) {
    return ContentAwareHashBuildsMatcher._(
      _delegate.having((cah) => cah.status, 'status', matcherOr),
    );
  }

  ContentAwareHashBuildsMatcher hasCreatedOn(Object? matcherOr) {
    return ContentAwareHashBuildsMatcher._(
      _delegate.having((cah) => cah.createdOn, 'createdOn', matcherOr),
    );
  }

  ContentAwareHashBuildsMatcher hasCommitSha(Object? matcherOr) {
    return ContentAwareHashBuildsMatcher._(
      _delegate.having((cah) => cah.commitSha, 'commitSha', matcherOr),
    );
  }

  ContentAwareHashBuildsMatcher hasContentHash(Object? matcherOr) {
    return ContentAwareHashBuildsMatcher._(
      _delegate.having((cah) => cah.contentHash, 'contentHash', matcherOr),
    );
  }

  ContentAwareHashBuildsMatcher hasWaitingShas(Object? matcherOr) {
    return ContentAwareHashBuildsMatcher._(
      _delegate.having(
        (status) => status.waitingShas,
        'waitingShas',
        matcherOr,
      ),
    );
  }
}
