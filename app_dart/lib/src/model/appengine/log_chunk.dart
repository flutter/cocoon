// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class representing a chunk of log output that was captured while running
/// a [Task].
@Kind(name: 'LogChunk')
class LogChunk extends Model<int> {
  /// Creates a new [LogChunk].
  LogChunk({
    Key<int> key,
    this.data,
    this.createTimestamp,
    this.ownerKey,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  /// The binary data of the log chunk.
  @BlobProperty(propertyName: 'Data', required: true)
  List<int> data;

  /// The timestamp (in milliseconds since the Epoch) that this log chunk was
  /// created.
  @IntProperty(propertyName: 'CreateTimestamp', required: true)
  int createTimestamp;

  /// The key of the [Model] entity with which this log is associated.
  @ModelKeyProperty(propertyName: 'OwnerKey', required: true)
  Key ownerKey;

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', data: $data')
      ..write(', createTimestamp: $createTimestamp')
      ..write(', ownerKey: ${ownerKey?.id}')
      ..write(')');
    return buf.toString();
  }
}
