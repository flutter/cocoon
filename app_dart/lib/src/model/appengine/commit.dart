// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:json_annotation/json_annotation.dart';

import 'key_converter.dart';

part 'commit.g.dart';

/// Class that represents a commit that has landed on the master branch of a
/// Flutter repository.
@Kind(name: 'Checklist', idType: IdType.String)
class Commit extends Model {
  Commit({
    Key key,
    this.timestamp,
    this.sha,
    this.author,
    this.authorAvatarUrl,
    this.repository,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

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

@JsonSerializable(createFactory: false, ignoreUnannotated: true)
class CommitWrapper {
  const CommitWrapper(this.commit);

  final Commit commit;

  @JsonKey(name: 'Key')
  @KeyConverter()
  Key get key => commit.key;

  @JsonKey(name: 'Checklist')
  Map<String, dynamic> get facade {
    return <String, dynamic>{
      'FlutterRepositoryPath': commit.repository,
      'CreateTimestamp': commit.timestamp,
      'Commit': <String, dynamic>{
        'Sha': commit.sha,
        'Author': <String, dynamic>{
          'Login': commit.author,
          'avatar_url': commit.authorAvatarUrl,
        },
      },
    };
  }

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$CommitWrapperToJson(this);
}
