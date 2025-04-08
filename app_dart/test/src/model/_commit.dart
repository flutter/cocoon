// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class CommitMatcher extends ModelMatcher<Commit> {
  const CommitMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<Commit> get metadata => Commit.metadata;

  CommitMatcher hasAvatar(Object? matcherOr) {
    return CommitMatcher._(
      _delegate.having((Commit commit) => commit.avatar, 'avatar', matcherOr),
    );
  }

  CommitMatcher hasBranch(Object? matcherOr) {
    return CommitMatcher._(
      _delegate.having((Commit commit) => commit.branch, 'branch', matcherOr),
    );
  }

  CommitMatcher hasCreateTimestamp(Object? matcherOr) {
    return CommitMatcher._(
      _delegate.having(
        (Commit commit) => commit.createTimestamp,
        'createTimestamp',
        matcherOr,
      ),
    );
  }

  CommitMatcher hasAuthor(Object? matcherOr) {
    return CommitMatcher._(
      _delegate.having((Commit commit) => commit.author, 'author', matcherOr),
    );
  }

  CommitMatcher hasMessage(Object? matcherOr) {
    return CommitMatcher._(
      _delegate.having((Commit commit) => commit.message, 'message', matcherOr),
    );
  }

  CommitMatcher hasRepositoryPath(Object? matcherOr) {
    return CommitMatcher._(
      _delegate.having(
        (Commit commit) => commit.repositoryPath,
        'repositoryPath',
        matcherOr,
      ),
    );
  }

  CommitMatcher hasSha(Object? matcherOr) {
    return CommitMatcher._(
      _delegate.having((Commit commit) => commit.sha, 'sha', matcherOr),
    );
  }
}
