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
import '../service/logging.dart';

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
      log.info('create branch event was rejected because could not parse the json webhook request');
      throw const BadRequestException('Expected create request event.');
    }

    final String? refType = createEvent.refType;
    if (refType == 'tag') {
      log.info('create branch event was rejected because it is a tag');
      return;
    }
    final String? branch = createEvent.ref;
    final String repository = createEvent.repository!.slug().fullName;
    final int lastActivity = createEvent.repository!.pushedAt!.millisecondsSinceEpoch;
    final bool forked = createEvent.repository!.isFork;

    if (forked) {
      log.info('create branch event was rejected because the branch is a fork');
      return;
    }

    final String id = '$repository/$branch';
    log.info('the id used to create branch key was $id');
    final Key<String> key = datastore.db.emptyKey.append<String>(Branch, id: id);
    final Branch currentBranch = Branch(key: key, lastActivity: lastActivity);
    try {
      await datastore.lookupByValue<Branch>(currentBranch.key);
    } on KeyNotFoundException {
      log.info('create branch event was successful since the key is unique');
      await datastore.insert(<Branch>[currentBranch]);
    } catch (e) {
      log.severe('Unexpected exception was encountered while inserting branch into database: $e');
    }
  }

  Future<CreateEvent?> _getCreateRequestEvent(String request) async {
    try {
      return CreateEvent.fromJson(json.decode(request) as Map<String, dynamic>);
    } on FormatException {
      return null;
    } catch (e) {
      log.severe('Unexpected exception was encountered while decoding json webhook msg for branch creation: $e');
      return null;
    }
  }
}
