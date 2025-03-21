// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_server/logging.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../service/datastore.dart';

part 'commit.g.dart';

/// Class that represents a commit that has landed on the master branch of a
/// Flutter repository.
@Kind(name: 'Checklist', idType: IdType.String)
class Commit extends Model<String> {
  Commit({
    Key<String>? key,
    this.sha,
    this.timestamp,
    this.author,
    this.authorAvatarUrl,
    this.message,
    this.repository,
    this.branch = 'master',
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  /// Create a [Key] that can be used to lookup a [Commit] from Datastore.
  static Key<String> createKey({
    required DatastoreDB db,
    required RepositorySlug slug,
    required String gitBranch,
    required String sha,
  }) {
    return db.emptyKey.append(Commit, id: '${slug.fullName}/$gitBranch/$sha');
  }

  /// Lookup [Commit] from Datastore.
  static Future<Commit> fromDatastore({
    required DatastoreService datastore,
    required Key<String> key,
  }) async {
    log.debug('Looking up commit by key with id: ${key.id}');
    return datastore.lookupByValue<Commit>(key);
  }

  /// The timestamp (in milliseconds since the Epoch) of when the commit
  /// landed.
  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  int? timestamp;

  /// The SHA1 hash of the commit.
  @StringProperty(propertyName: 'Commit.Sha', required: true)
  String? sha;

  /// The GitHub username of the commit author.
  @StringProperty(propertyName: 'Commit.Author.Login')
  String? author;

  /// URL of the [author]'s profile image / avatar.
  ///
  /// The bytes loaded from the URL are expected to be encoded image bytes.
  @StringProperty(propertyName: 'Commit.Author.AvatarURL')
  String? authorAvatarUrl;

  /// The commit message.
  ///
  /// This may be null, since we didn't always load/store this property in
  /// the datastore, so historical entries won't have this information.
  @StringProperty(propertyName: 'Commit.Message', required: false)
  String? message;

  /// A serializable form of [slug].
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  @StringProperty(propertyName: 'FlutterRepositoryPath', required: true)
  String? repository;

  /// The branch of the commit.
  @StringProperty(propertyName: 'Branch')
  String? branch;

  /// [RepositorySlug] of where this commit exists.
  RepositorySlug get slug => RepositorySlug.full(repository!);

  @override
  String toString() {
    final buf =
        StringBuffer()
          ..write('$runtimeType(')
          ..write('id: $id')
          ..write(', parentKey: ${parentKey?.id}')
          ..write(', key: ${parentKey == null ? null : key.id}')
          ..write(', timestamp: $timestamp')
          ..write(', sha: $sha')
          ..write(', author: $author')
          ..write(', authorAvatarUrl: $authorAvatarUrl')
          ..write(', message: ${message?.split("\n").first}')
          ..write(', repository: $repository')
          ..write(', branch: $branch')
          ..write(')');
    return buf.toString();
  }
}
