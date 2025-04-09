// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class PrCheckRunsMatcher extends ModelMatcher<PrCheckRuns> {
  const PrCheckRunsMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<PrCheckRuns> get metadata => PrCheckRuns.metadata;

  PrCheckRunsMatcher hasPullRequest(Object valueOrMatcher) {
    return PrCheckRunsMatcher._(
      _delegate.having((c) => c.pullRequest, 'pullRequest', valueOrMatcher),
    );
  }

  PrCheckRunsMatcher hasSha(Object valueOrMatcher) {
    return PrCheckRunsMatcher._(
      _delegate.having((c) => c.sha, 'sha', valueOrMatcher),
    );
  }

  PrCheckRunsMatcher hasSlug(Object valueOrMatcher) {
    return PrCheckRunsMatcher._(
      _delegate.having((c) => c.slug, 'slug', valueOrMatcher),
    );
  }

  PrCheckRunsMatcher hasCheckRuns(Object valueOrMatcher) {
    return PrCheckRunsMatcher._(
      _delegate.having((c) => c.checkRuns, 'checkRuns', valueOrMatcher),
    );
  }
}
