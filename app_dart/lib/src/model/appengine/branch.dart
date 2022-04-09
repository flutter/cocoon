// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:github/github.dart';

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

class SerializableBranch {
  const SerializableBranch(this.branch, this.id);

  final Branch branch;
  final String id; // this id is in datastore format and different from branch.id

  Map<String, dynamic> get facade {
    return <String, dynamic>{
      'branch': branch.branch,
      'repository': branch.repository,
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'branch': facade,
    };
  }
}
