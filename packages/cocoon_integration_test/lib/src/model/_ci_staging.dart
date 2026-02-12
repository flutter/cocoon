// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class CiStagingMatcher extends ModelMatcher<CiStaging> {
  const CiStagingMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<CiStaging> get metadata {
    return CiStaging.metadata;
  }

  CiStagingMatcher hasSlug(Object? matcherOr) {
    return CiStagingMatcher._(
      _delegate.having((m) => m.slug, 'slug', matcherOr),
    );
  }

  CiStagingMatcher hasSha(Object? matcherOr) {
    return CiStagingMatcher._(_delegate.having((m) => m.sha, 'sha', matcherOr));
  }

  CiStagingMatcher hasStage(Object? matcherOr) {
    return CiStagingMatcher._(
      _delegate.having((m) => m.stage, 'stage', matcherOr),
    );
  }

  CiStagingMatcher hasRemaining(Object? matcherOr) {
    return CiStagingMatcher._(
      _delegate.having((m) => m.remaining, 'remaining', matcherOr),
    );
  }

  CiStagingMatcher hasTotal(Object? matcherOr) {
    return CiStagingMatcher._(
      _delegate.having((m) => m.total, 'total', matcherOr),
    );
  }

  CiStagingMatcher hasFailed(Object? matcherOr) {
    return CiStagingMatcher._(
      _delegate.having((m) => m.failed, 'failed', matcherOr),
    );
  }

  CiStagingMatcher hasCheckRunGuard(Object? matcherOr) {
    return CiStagingMatcher._(
      _delegate.having((m) => m.checkRunGuard, 'checkRunGuard', matcherOr),
    );
  }

  CiStagingMatcher hasCheckRuns(Object? matcherOr) {
    return CiStagingMatcher._(
      _delegate.having((m) => m.checkRuns, 'checkRuns', matcherOr),
    );
  }
}
