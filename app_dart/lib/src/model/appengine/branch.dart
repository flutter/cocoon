// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/src/model/appengine/key_converter.dart';
import 'package:gcloud/db.dart';
import 'package:github/github.dart';
import 'package:json_annotation/json_annotation.dart';

part 'branch.g.dart';

@Kind(name: 'Branch', idType: IdType.String)
class Branch extends Model<String> {
  Branch({Key<String>? key, this.lastActivity, this.channel}) {
    parentKey = key?.parent;
    id = key?.id;
  }

  /// The timestamp (in milliseconds since the Epoch) of the last time
  /// when current branch had activity.
  @IntProperty(propertyName: 'lastActivity', required: false)
  int? lastActivity;

  /// The channel of current branch
  @StringProperty(propertyName: 'channel', required: false)
  String? channel;

  /// [RepositorySlug] of where this commit exists.
  RepositorySlug get slug => RepositorySlug.full(repository);

  String get repository => key.id!.substring(0, key.id!.lastIndexOf('/'));

  String get branch => key.id!.substring(key.id!.lastIndexOf('/') + 1);

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', branch: $branch')
      ..write(', channel: $channel')
      ..write(', repository: $repository')
      ..write(', lastActivity: $lastActivity')
      ..write(')');
    return buf.toString();
  }
}

/// The serialized representation of a [Branch].
// TODO(tvolkert): Directly serialize [Branch] once frontends migrate to new serialization format.
@JsonSerializable(createFactory: false, ignoreUnannotated: true)
class SerializableBranch {
  const SerializableBranch(this.branch);

  final Branch branch;

  @JsonKey(name: 'Key')
  @StringKeyConverter()
  Key<String>? get key => branch.key;

  @JsonKey(name: 'Branch')
  Map<String, dynamic> get facade {
    return <String, dynamic>{
      'branch': branch.branch,
      'repository': branch.repository,
    };
  }

  /// Serializes this object to a JSON primitive.
  Map<String, dynamic> toJson() => _$SerializableBranchToJson(this);
}
