// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert' show json;

import 'package:github/server.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

@immutable
class GithubService{

  const GithubService(this.github, this.slug);

  final GitHub github;
  final RepositorySlug slug;

  String helper(String sha){
    return sha;
  }

  Future<List<dynamic>> checkRuns(
    RepositorySlug slug, String sha
  ) async {
    final String path = '/repos/${slug.fullName}/commits/$sha/check-runs';
    final Response response = await github.request('GET', path,
        headers: <String, String>{'Accept': 'application/vnd.github.antiope-preview+json'});

    if (response.statusCode == 202) {
      throw NotReady(github, path);
    } else if (response.statusCode != 200) {
      github.handleStatusCode(response);
    } else {
      final Map<String, dynamic> jsonStatus = json.decode(response.body);
      return jsonStatus['check_runs'];
    }
  }
}