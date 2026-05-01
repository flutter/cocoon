// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:github/github.dart';
import 'package:googleapis/firestore/v1.dart';

import '../../service/firestore.dart';
import 'base.dart';

/// Represents the state of a Pull Request that we want to persist across events.
final class PullRequestState extends AppDocument<PullRequestState> {
  static const kCollectionId = 'pullRequestStates';
  static const kIsPrivilegedField = 'is_privileged';
  static const kLatestShaField = 'latest_sha';
  static const kScheduledShaField = 'scheduled_sha';
  static const kSlugField = 'slug';
  static const kNumberField = 'number';

  @override
  AppDocumentMetadata<PullRequestState> get runtimeMetadata => metadata;

  /// Description of the document in Firestore.
  static final metadata = AppDocumentMetadata<PullRequestState>(
    collectionId: kCollectionId,
    fromDocument: PullRequestState.fromDocument,
  );

  /// Create [PullRequestState] from a Document.
  static PullRequestState fromDocument(Document doc) {
    return PullRequestState()
      ..fields = doc.fields!
      ..name = doc.name!;
  }

  /// Whether the PR author is a privileged user (roller or flutter-hacker).
  bool? get isPrivileged => fields[kIsPrivilegedField]?.booleanValue;

  set isPrivileged(bool? value) {
    if (value != null) {
      fields[kIsPrivilegedField] = value.toValue();
    }
  }

  /// The latest SHA that we have processed for this PR.
  String? get latestSha => fields[kLatestShaField]?.stringValue;

  set latestSha(String? value) {
    if (value != null) {
      fields[kLatestShaField] = value.toValue();
    }
  }

  /// The SHA for which we have scheduled presubmits.
  String? get scheduledSha => fields[kScheduledShaField]?.stringValue;

  set scheduledSha(String? value) {
    if (value != null) {
      fields[kScheduledShaField] = value.toValue();
    }
  }

  /// The repository slug associated with the pull request.
  RepositorySlug get slug => RepositorySlug.fromJson(
    json.decode(fields[kSlugField]!.stringValue!) as Map<String, Object?>,
  );

  set slug(RepositorySlug value) {
    fields[kSlugField] = json.encode(value.toJson()).toValue();
  }

  /// The PR number.
  int get number => int.parse(fields[kNumberField]!.integerValue!);

  set number(int value) {
    fields[kNumberField] = value.toValue();
  }

  /// Generates the document ID for a PR.
  static String getDocumentId(RepositorySlug slug, int number) {
    return '${slug.owner}\u001F${slug.name}\u001F$number';
  }
}
