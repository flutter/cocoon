// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents an update having been posted to a GitHub PR on the
/// status of the Flutter build.
@Kind(name: 'GithubBuildStatusUpdate')
class GithubBuildStatusUpdate extends Model {
  GithubBuildStatusUpdate({
    Key key,
    this.repository,
    this.pr,
    this.head,
    this.status,
    this.updates,
    this.updateTimestamp,
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

  @StringProperty(propertyName: 'Status', required: true)
  String status;

  @IntProperty(propertyName: 'Updates', required: true)
  int updates;

  @IntProperty(propertyName: 'UpdateTimestamp')
  int updateTimestamp;

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
      ..write(', lastStatus: $status')
      ..write(', updates: $updates')
      ..write(', updateTimestamp: $updateTimestamp')
      ..write(')');
    return buf.toString();
  }
}
