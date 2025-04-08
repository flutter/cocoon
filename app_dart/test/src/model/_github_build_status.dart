// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class GithubBuildStatusMatcher extends ModelMatcher<GithubBuildStatus> {
  const GithubBuildStatusMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<GithubBuildStatus> get metadata {
    return GithubBuildStatus.metadata;
  }

  GithubBuildStatusMatcher hasPrNumber(Object? matcherOr) {
    return GithubBuildStatusMatcher._(
      _delegate.having(
        (GithubBuildStatus status) => status.prNumber,
        'prNumber',
        matcherOr,
      ),
    );
  }

  GithubBuildStatusMatcher hasRepository(Object? matcherOr) {
    return GithubBuildStatusMatcher._(
      _delegate.having(
        (GithubBuildStatus status) => status.repository,
        'repository',
        matcherOr,
      ),
    );
  }

  GithubBuildStatusMatcher hasHead(Object? matcherOr) {
    return GithubBuildStatusMatcher._(
      _delegate.having(
        (GithubBuildStatus status) => status.head,
        'head',
        matcherOr,
      ),
    );
  }

  GithubBuildStatusMatcher hasStatus(Object? matcherOr) {
    return GithubBuildStatusMatcher._(
      _delegate.having(
        (GithubBuildStatus status) => status.status,
        'status',
        matcherOr,
      ),
    );
  }

  GithubBuildStatusMatcher hasUpdateTimeMillis(Object? matcherOr) {
    return GithubBuildStatusMatcher._(
      _delegate.having(
        (GithubBuildStatus status) => status.updateTimeMillis,
        'updateTimeMillis',
        matcherOr,
      ),
    );
  }

  GithubBuildStatusMatcher hasUpdates(Object? matcherOr) {
    return GithubBuildStatusMatcher._(
      _delegate.having(
        (GithubBuildStatus status) => status.updates,
        'updates',
        matcherOr,
      ),
    );
  }
}
