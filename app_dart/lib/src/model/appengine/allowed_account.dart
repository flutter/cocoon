// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents a non-Google account that has been allowlisted to
/// make API requests to the Flutter dashboard.
///
/// By default, only App Engine cronjobs, and users
/// authenticated as "@google.com" accounts are allowed to make API requests
/// to the Cocooon backend. This class represents instances where non-Google
/// users have been explicitly allowlisted to make such requests.
@Kind(name: 'AllowedAccount')
class AllowedAccount extends Model<int> {
  /// Creates a new [AllowedAccount].
  AllowedAccount({
    Key<int>? key,
  }) {
    parentKey = key?.parent;
    id = key?.id;
  }

  /// The email address of the account that has been allowlisted.
  @StringProperty(propertyName: 'Email', required: true)
  String email = '';

  @override
  String toString() {
    final StringBuffer buf = StringBuffer()
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey?.id}')
      ..write(', key: ${parentKey == null ? null : key.id}')
      ..write(', email: $email')
      ..write(')');
    return buf.toString();
  }
}
