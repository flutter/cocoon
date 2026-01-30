// Copyright 2024 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of 'firestore_matcher.dart';

final class GithubWebhookMessageMatcher
    extends ModelMatcher<GithubWebhookMessage> {
  const GithubWebhookMessageMatcher._(super._delegate) : super._();

  @override
  AppDocumentMetadata<GithubWebhookMessage> get metadata {
    return GithubWebhookMessage.metadata;
  }

  GithubWebhookMessageMatcher hasEvent(Object? matcherOr) {
    return GithubWebhookMessageMatcher._(
      _delegate.having((message) => message.event, 'event', matcherOr),
    );
  }

  GithubWebhookMessageMatcher hasTimestamp(Object? matcherOr) {
    return GithubWebhookMessageMatcher._(
      _delegate.having((message) => message.timestamp, 'timestamp', matcherOr),
    );
  }

  GithubWebhookMessageMatcher hasJsonString(Object? matcherOr) {
    return GithubWebhookMessageMatcher._(
      _delegate.having(
        (message) => message.jsonString,
        'jsonString',
        matcherOr,
      ),
    );
  }
}
