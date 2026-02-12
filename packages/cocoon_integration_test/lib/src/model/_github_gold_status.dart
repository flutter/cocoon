// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class GithubGoldStatusMatcher extends ModelMatcher<GithubGoldStatus> {
  const GithubGoldStatusMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<GithubGoldStatus> get metadata {
    return GithubGoldStatus.metadata;
  }

  GithubGoldStatusMatcher hasPrNumber(Object? matcherOr) {
    return GithubGoldStatusMatcher._(
      _delegate.having(
        (GithubGoldStatus status) => status.prNumber,
        'prNumber',
        matcherOr,
      ),
    );
  }

  GithubGoldStatusMatcher hasHead(Object? matcherOr) {
    return GithubGoldStatusMatcher._(
      _delegate.having(
        (GithubGoldStatus status) => status.head,
        'head',
        matcherOr,
      ),
    );
  }

  GithubGoldStatusMatcher hasStatus(Object? matcherOr) {
    return GithubGoldStatusMatcher._(
      _delegate.having(
        (GithubGoldStatus status) => status.status,
        'status',
        matcherOr,
      ),
    );
  }

  GithubGoldStatusMatcher hasDescription(Object? matcherOr) {
    return GithubGoldStatusMatcher._(
      _delegate.having(
        (GithubGoldStatus status) => status.description,
        'description',
        matcherOr,
      ),
    );
  }

  GithubGoldStatusMatcher hasUpdates(Object? matcherOr) {
    return GithubGoldStatusMatcher._(
      _delegate.having(
        (GithubGoldStatus status) => status.updates,
        'updates',
        matcherOr,
      ),
    );
  }

  GithubGoldStatusMatcher hasRepository(Object? matcherOr) {
    return GithubGoldStatusMatcher._(
      _delegate.having(
        (GithubGoldStatus status) => status.repository,
        'repository',
        matcherOr,
      ),
    );
  }
}
