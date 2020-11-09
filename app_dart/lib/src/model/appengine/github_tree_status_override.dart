// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents an update having been posted to a GitHub PR on the
/// status of the Flutter build.
@Kind(name: 'GithubTreeStatusOverride')
class GithubTreeStatusOverride extends Model {
  GithubTreeStatusOverride({
    Key key,
    this.repository,
    this.closed,
    this.user,
    this.reason,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  @StringProperty(propertyName: 'repository', required: true)
  String repository;

  @BoolProperty(propertyName: 'closed', required: true)
  bool closed;

  @StringProperty(propertyName: 'user', required: true)
  String user;

  @StringProperty(propertyName: 'reason', required: true)
  String reason;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', repository: $repository')
      ..write(', closed: $closed')
      ..write(', user: $user')
      ..write(', reason: $reason')
      ..write(')');
    return buf.toString();
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'repository': repository,
      'closed': closed,
      'user': user,
      'reason': reason,
    };
  }
}

/// Class that represents an update having been posted to a GitHub repository
/// PR on whether the tree is open or not.
@Kind(name: 'GitHubTreeStatusOverride')
class GitHubTreeStatusOverride extends Model {
  GitHubTreeStatusOverride({
    Key key,
    this.repository,
    this.pr,
    this.head,
    this.closed,
    this.updates,
    this.updateTimeMillis,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  static const String statusSuccess = 'success';

  static const String statusFailure = 'failure';

  @StringProperty(propertyName: 'Repository', required: true)
  String repository;

  @IntProperty(propertyName: 'PR', required: true)
  int pr;

  @StringProperty(propertyName: 'Head')
  String head;

  @BoolProperty(propertyName: 'Closed', required: true)
  bool closed;

  @IntProperty(propertyName: 'Updates', required: true)
  int updates;

  /// The last time when the status is updated for the PR.
  @IntProperty(propertyName: 'UpdateTimeMillis')
  int updateTimeMillis;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', repository: $repository')
      ..write(', pr: $pr')
      ..write(', head: $head')
      ..write(', lastStatus: $closed')
      ..write(', updates: $updates')
      ..write(', updateTimeMillis: $updateTimeMillis')
      ..write(')');
    return buf.toString();
  }
}
