// Copyright 2021 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:cocoon_service/src/service/datastore.dart';
import 'package:gcloud/db.dart';
import 'package:github/hooks.dart';

import '../model/appengine/branch.dart';
import '../request_handling/exceptions.dart';

class RetryException implements Exception {}

/// A class to manage GitHub branches.
///
/// Track branch activities such as branch creation, and helps manage release branches.
class BranchService {
  BranchService(this.datastore, {this.rawRequest});

  DatastoreService datastore;
  String? rawRequest;

  /// Parse a create github webhook event, and add it to datastore.
  Future<void> handleCreateRequest() async {
    final CreateEvent? createEvent = await _getCreateRequestEvent(rawRequest!);
    if (createEvent == null) {
      throw const BadRequestException('Expected create request event.');
    }

    final String? refType = createEvent.refType;
    if (refType == 'tag') {
      return;
    }
    final String? branch = createEvent.ref;
    final String? repository = createEvent.repository!.slug().fullName;
    final int lastActivity = createEvent.repository!.pushedAt!.millisecondsSinceEpoch;

    final String id = '$repository/$branch';
    final Key<String> key = datastore.db.emptyKey.append<String>(Branch, id: id);
    final Branch currentBranch = Branch(key: key, lastActivity: lastActivity);
    try {
      await datastore.lookupByValue<Branch>(currentBranch.key);
    } on KeyNotFoundException {
      await datastore.insert(<Branch>[currentBranch]);
    }
  }

  Future<CreateEvent?> _getCreateRequestEvent(String request) async {
    try {
      return CreateEvent.fromJson(json.decode(request) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }
}
