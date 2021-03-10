// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';

part 'commit.g.dart';

/// Class that represents a commit that has landed on the master branch of a
/// Flutter repository.
@Kind(name: 'Checklist', idType: IdType.String)
@JsonSerializable(ignoreUnannotated: true)
class Commit extends Model<String> {
  Commit({
    Key<String> key,
    this.timestamp,
    this.sha,
    this.author,
    this.authorAvatarUrl,
    @visibleForTesting
    this.encodedKeyValue,
    this.message,
    this.repository,
    this.branch = 'master',
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  factory Commit.fromJson(Map<String, dynamic> json) => _$CommitFromJson(json);

  /// The timestamp (in milliseconds since the Epoch) of when the commit
  /// landed.
  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  @JsonKey()
  int timestamp;

  /// The SHA1 hash of the commit.
  @StringProperty(propertyName: 'Commit.Sha', required: true)
  @JsonKey()
  String sha;

  /// JSON safe version of [Key]. Each entity can construct keys differently, so
  /// explicitly define it.
  @JsonKey(name: 'key')
  String get encodedKey => encodedKeyValue ?? key.id;

  /// Value for injecting encoded key in test environments.
  final String encodedKeyValue;

  /// The GitHub username of the commit author.
  @StringProperty(propertyName: 'Commit.Author.Login', required: true)
  @JsonKey()
  String author;

  /// URL of the [author]'s profile image / avatar.
  ///
  /// The bytes loaded from the URL are expected to be encoded image bytes.
  @StringProperty(propertyName: 'Commit.Author.AvatarURL', required: true)
  @JsonKey()
  String authorAvatarUrl;

  /// The commit message.
  ///
  /// This may be null, since we didn't always load/store this property in
  /// the datastore, so historical entries won't have this information.
  @StringProperty(propertyName: 'Commit.Message', required: false)
  @JsonKey()
  String message;

  /// The repository on which the commit was made.
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  @StringProperty(propertyName: 'FlutterRepositoryPath', required: true)
  @JsonKey()
  String repository;

  /// The branch of the commit.
  @StringProperty(propertyName: 'Branch')
  @JsonKey()
  String branch;

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
      ..write(', message: ${message?.split("\n")?.first}')
      ..write(', repository: $repository')
      ..write(', branch: $branch')
      ..write(')');
    return buf.toString();
  }

  Map<String, dynamic> toJson() => _$CommitToJson(this);
}
