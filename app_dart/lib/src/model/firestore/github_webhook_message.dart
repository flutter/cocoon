// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:googleapis/firestore/v1.dart' as g;

import '../../service/firestore.dart';
import 'base.dart';

/// A Webhook message received by `GithubWebhook` handler.
final class GithubWebhookMessage extends AppDocument<GithubWebhookMessage> {
  @override
  AppDocumentMetadata<GithubWebhookMessage> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<GithubWebhookMessage>(
    collectionId: 'github_webhook_messages',
    fromDocument: GithubWebhookMessage.fromDocument,
  );

  factory GithubWebhookMessage({
    required String event,
    required String jsonString,
    required DateTime timestamp,
    required DateTime expireAt,
  }) {
    return GithubWebhookMessage.fromDocument(
      g.Document(
        fields: {
          _fieldTimestamp: timestamp.toValue(),
          _fieldEvent: event.toValue(),
          _fieldJsonString: jsonString.toValue(),
          _fieldExpireAt: expireAt.toValue(),
        },
      ),
    );
  }

  /// Create [GithubWebhookMessage] from a GithubBuildStatus Document.
  GithubWebhookMessage.fromDocument(super.document);

  static const _fieldTimestamp = 'timestamp';
  static const _fieldEvent = 'event';
  static const _fieldJsonString = 'jsonString';
  static const _fieldExpireAt = 'expireAt';

  DateTime get timestamp {
    return DateTime.parse(fields[_fieldTimestamp]!.timestampValue!);
  }

  String get event {
    return fields[_fieldEvent]!.stringValue!;
  }

  String get jsonString {
    return fields[_fieldJsonString]!.stringValue!;
  }

  DateTime get expireAt {
    return DateTime.parse(fields[_fieldExpireAt]!.timestampValue!);
  }
}
