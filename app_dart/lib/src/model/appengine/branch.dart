// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';
import 'package:github/github.dart';

@Kind(name: 'Branch', idType: IdType.String)
class Branch extends Model<String> {
  Branch({Key<String>? key, this.branch, this.defaultBranch, this.repository}) {
    parentKey = key?.parent;
    id = key?.id;
  }

  /// The branch name of the current branch
  @StringProperty(propertyName: 'branch', required: true)
  String? branch;

  /// A serializable form of [RepositorySlug].
  ///
  /// This will be of the form `<org>/<repo>`. e.g. `flutter/flutter`.
  @StringProperty(propertyName: 'FlutterRepositoryPath', required: true)
  String? repository;

  /// The default branch of the repository which hosts current branch.
  /// If current branch is not the default branch, current branch is likely a release branch.
  @StringProperty(propertyName: 'defaultBranch', required: true)
  String? defaultBranch;

  /// [RepositorySlug] of where this commit exists.
  RepositorySlug get slug => RepositorySlug.full(repository!);

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', branch: $branch')
      ..write(', defaultBranch: $defaultBranch')
      ..write(', repository: $repository')
      ..write(')');
    return buf.toString();
  }
}
