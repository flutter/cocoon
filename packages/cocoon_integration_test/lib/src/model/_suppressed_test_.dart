// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class SuppressedTestMatcher extends ModelMatcher<SuppressedTest> {
  const SuppressedTestMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<SuppressedTest> get metadata {
    return SuppressedTest.metadata;
  }

  SuppressedTestMatcher hasCreateTimestamp(Object? matcherOr) {
    return SuppressedTestMatcher._(
      _delegate.having((t) => t.createTimestamp, 'createTimestamp', matcherOr),
    );
  }

  SuppressedTestMatcher hasIsSuppressed(Object? matcherOr) {
    return SuppressedTestMatcher._(
      _delegate.having((t) => t.isSuppressed, 'isSuppressed', matcherOr),
    );
  }

  SuppressedTestMatcher hasIssueLink(Object? matcherOr) {
    return SuppressedTestMatcher._(
      _delegate.having((t) => t.issueLink, 'issueLink', matcherOr),
    );
  }

  SuppressedTestMatcher hasRepository(Object? matcherOr) {
    return SuppressedTestMatcher._(
      _delegate.having((t) => t.repository, 'repository', matcherOr),
    );
  }

  SuppressedTestMatcher hasTestName(Object? matcherOr) {
    return SuppressedTestMatcher._(
      _delegate.having((t) => t.testName, 'name', matcherOr),
    );
  }

  SuppressedTestMatcher hasUpdates(Object? matcherOr) {
    return SuppressedTestMatcher._(
      _delegate.having((t) => t.updates, 'updates', matcherOr),
    );
  }
}
