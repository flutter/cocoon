// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cocoon_service/protos.dart' show CommitStatus;
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'cocoon.dart';

/// CocoonService for interacting with flutter/flutter production build data.
///
/// This queries API endpoints that are hosted on AppEngine.
class AppEngineCocoonService implements CocoonService {
  /// The Cocoon API endpoint to query
  ///
  /// This is the base for all API requests to cocoon
  static const baseApiUrl = 'https://flutter-dashboard.appspot.com/api';

  http.Client client = http.Client();

  @override
  Future<List<CommitStatus>> getStats() async {
    /// This endpoint returns a JSON [List<Agent>, List<CommitStatus>]
    var response = await client.get('$baseApiUrl/public/get-status');

    return _jsonDecodeCommitStatuses(jsonDecode(response.body)[1]);
  }

  List<CommitStatus> _jsonDecodeCommitStatuses(List<String> pieces) {
    List<CommitStatus> statuses = List();

    pieces.map((piece) => statuses.add(CommitStatus.fromJson(piece)));

    return statuses;
  }
}
