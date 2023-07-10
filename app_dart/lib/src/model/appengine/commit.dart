// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../service/datastore.dart';
import '../../service/logging.dart';
import 'key_converter.dart';

import 'package:cocoon_service/src/model/luci/buildbucket.dart' as bb;

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
    return db.emptyKey.append(
      Commit,
      id: '${slug.fullName}/$gitBranch/$sha',
    );
  }

  /// Create a [Key] that can be used to lookup a [Commit] from Datastore based on a buildbucket object
  static Key<String> createKeyFromBuildbucketBuild({required DatastoreDB db, required bb.Build build})
  {
    log.fine("Generating commit key from buildbucket build: ${build.toString()}");
    // Example: "flutter" from "mirrors/flutter".
    final String repository = build.input!.gitilesCommit!.project!.split('/')[1];
    // Example: "stable" from "refs/heads/stable".
    final String gitBranch = build.input!.gitilesCommit!.ref!.split('/')[2];
    final String sha = build.input!.gitilesCommit!.hash!;
    final RepositorySlug slug = RepositorySlug("flutter", repository);

    return db.emptyKey.append(
      Commit,
      id: '${slug.fullName}/$gitBranch/$sha',
    );
  }

  /// Lookup [Commit] from Datastore.
  static Future<Commit> fromDatastore({
    required DatastoreService datastore,
    required Key<String> key,
  }) async {
    log.fine('Looking up commit by key with id: ${key.id}');
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
    final StringBuffer buf = StringBuffer()
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

/// The serialized representation of a [Commit].
// TODO(tvolkert): Directly serialize [Commit] once frontends migrate to new serialization format.
@JsonSerializable(createFactory: false, ignoreUnannotated: true)
class SerializableCommit {
  const SerializableCommit(this.commit);

  final Commit commit;

  @JsonKey(name: 'Key')
  @StringKeyConverter()
  Key<String>? get key => commit.key;

  @JsonKey(name: 'Checklist')
  Map<String, dynamic> get facade {
    return <String, dynamic>{
      'FlutterRepositoryPath': commit.repository,
      'CreateTimestamp': commit.timestamp,
      'Commit': <String, dynamic>{
        'Sha': commit.sha,
        'Message': commit.message,
        'Author': <String, dynamic>{
          'Login': commit.author,
          'avatar_url': commit.authorAvatarUrl,
        },
      },
      'Branch': commit.branch,
    };
  }

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$SerializableCommitToJson(this);
}
