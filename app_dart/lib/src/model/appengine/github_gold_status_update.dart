// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents an update having been posted to a GitHub
/// flutter/flutter PR on the status of tryjobs generated on Flutter Gold.
@Kind(name: 'GithubGoldStatusUpdate')
class GithubGoldStatusUpdate extends Model<int> {
  GithubGoldStatusUpdate({
    Key<int>? key,
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

  // The flutter-gold status cannot report a `failure` status
  // due to auto-rollers. This is why we hold a `pending` status
  // when there are image changes. This provides the opportunity
  // for images to be triaged, and the auto-roller to proceed.
  // For more context, see: https://github.com/flutter/flutter/issues/48744

  static const String statusCompleted = 'success';

  static const String statusRunning = 'pending';

  @IntProperty(propertyName: 'PR', required: true)
  int? pr;

  @StringProperty(propertyName: 'Head')
  String? head;

  @StringProperty(propertyName: 'Status', required: true)
  String? status;

  @StringProperty(propertyName: 'Description', required: true)
  String? description;

  @IntProperty(propertyName: 'Updates', required: true)
  int? updates;

  @StringProperty(propertyName: 'Repository', required: true)
  String? repository;

  @override
  String toString() {
    final buf =
        StringBuffer()
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
