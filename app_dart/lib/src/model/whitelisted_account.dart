// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:gcloud/db.dart';

/// Class that represents a non-Google account that has been whitelisted to
/// make API requests to the Flutter dashboard.
///
/// By default, only registered agents, App Engine cronjobs, and users
/// authenticated as "@google.com" accounts are allowed to make API requests
/// to the Cocooon backend. This class represents instances where non-Google
/// users have been explicitly whitelisted to make such requests.
@Kind(name: 'WhitelistedAccount')
class WhitelistedAccount extends Model {
  /// Creates a new [WhitelistedAccount].
  WhitelistedAccount({this.email});

  /// The email address of the account that has been whitelisted.
  @StringProperty(propertyName: 'Email', required: true)
  String email;

  @override
  String toString() {
    StringBuffer buf = StringBuffer();
    buf
      ..write('$runtimeType(')
      ..write('id: $id')
      ..write(', parentKey: ${parentKey.id}')
      ..write(', key: ${key.id}')
      ..write(', email: $email')
      ..write(')');
    return buf.toString();
  }
}
