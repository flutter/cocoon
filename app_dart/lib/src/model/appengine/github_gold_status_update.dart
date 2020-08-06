// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents an update having been posted to a GitHub
/// flutter/flutter PR on the status of tryjobs generated on Flutter Gold.
@Kind(name: 'GithubGoldStatusUpdate')
class GithubGoldStatusUpdate extends Model {
  GithubGoldStatusUpdate({
    Key key,
    this.pr,
    this.head,
    this.status,
    this.description,
    this.updates,
    this.repository,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  static const String statusCompleted = 'success';

  static const String statusRunning = 'pending';

  @IntProperty(propertyName: 'PR', required: true)
  int pr;

  @StringProperty(propertyName: 'Head')
  String head;

  @StringProperty(propertyName: 'Status', required: true)
  String status;

  @StringProperty(propertyName: 'Description', required: true)
  String description;

  @IntProperty(propertyName: 'Updates', required: true)
  int updates;

  @StringProperty(propertyName: 'Repository', required: true)
  String repository;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', pr: $pr')
      ..write(', head: $head')
      ..write(', lastStatus: $status')
      ..write(', description $description')
      ..write(', updates: $updates')
      ..write(', repository: $repository')
      ..write(')');
    return buf.toString();
  }
}
