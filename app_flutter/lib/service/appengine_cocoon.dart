// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cocoon_service/protos.dart' show CommitStatus;

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
    http.Response response = await client.get('$baseApiUrl/public/get-status');

    if (response.statusCode != 200) {
      throw new HttpException(
          '$baseApiUrl/public/get-status returned ${response.statusCode}');
    }

    Map<String, dynamic> jsonResponse = jsonDecode(response.body);
    assert(jsonResponse != null);

    return _jsonDecodeCommitStatuses(jsonResponse['Statuses']);
  }

  List<CommitStatus> _jsonDecodeCommitStatuses(
      List<dynamic> jsonCommitStatuses) {
    assert(jsonCommitStatuses != null);

    List<CommitStatus> statuses = List();

    jsonCommitStatuses.map((jsonCommitStatus) {
      statuses.add(CommitStatus.fromJson(jsonCommitStatus));
    });

    return statuses;
  }
}
