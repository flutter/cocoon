// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents a commit that has landed on the master branch of a
/// Flutter repository.
@Kind(name: 'Checklist', idType: IdType.String)
class Commit extends Model {
  Commit({
    this.timestamp,
    this.sha,
    this.author,
    this.authorAvatarUrl,
    this.repository,
  });

  /// The timestamp (in milliseconds since the Epoch) of when the commit
  /// landed.
  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  int timestamp;

  /// The SHA1 hash of the commit.
  @StringProperty(propertyName: 'Commit.Sha', required: true)
  String sha;

  /// The GitHub username of the commit author.
  @StringProperty(propertyName: 'Commit.Author.Login', required: true)
  String author;

  /// URL of the [author]'s profile image / avatar.
  ///
  /// The bytes loaded from the URL are expected to be encoded image bytes.
  @StringProperty(propertyName: 'Commit.Author.AvatarURL', required: true)
  String authorAvatarUrl;

  /// The repository on which the commit was made.
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  @StringProperty(propertyName: 'FlutterRepositoryPath', required: true)
  String repository;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', timestamp: $timestamp')
      ..write(', sha: $sha')
      ..write(', author: $author')
      ..write(', authorAvatarUrl: $authorAvatarUrl')
      ..write(', repository: $repository')
      ..write(')');
    return buf.toString();
  }
}
