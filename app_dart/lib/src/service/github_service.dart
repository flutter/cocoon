// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
import 'dart:convert' show json;

import 'package:github/server.dart';
import 'package:http/http.dart';
import 'package:meta/meta.dart';

@immutable
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
class GithubService {
=======
<<<<<<< HEAD
=======
>>>>>>> c913cd0... changed to check API
class GithubService {
=======
class GithubService{

>>>>>>> 2f3aef4... initial investigation
<<<<<<< HEAD
>>>>>>> changed to check API
=======
class GithubService{

>>>>>>> 627c61a... initial investigation
=======
>>>>>>> c913cd0... changed to check API
=======
class GithubService {
>>>>>>> 6617e07... changed to check API
=======
class GithubService{

>>>>>>> 73a3106... initial investigation
=======
class GithubService{

>>>>>>> 2f3aef4... initial investigation
  const GithubService(this.github, this.slug);

  final GitHub github;
  final RepositorySlug slug;

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  Future<List<dynamic>> checkRuns(RepositorySlug slug, String sha) async {
=======
=======
>>>>>>> add test
<<<<<<< HEAD
=======
>>>>>>> c913cd0... changed to check API
  String helper(String sha) {
    return sha;
  }

<<<<<<< HEAD
=======
>>>>>>> cf8adcb... add test
  Future<List<dynamic>> checkRuns(RepositorySlug slug, String sha) async {
    final String path = '/repos/${slug.fullName}/commits/$sha/check-runs';
    final PaginationHelper paginationHelper = PaginationHelper(github);
    final List<dynamic> runStatus = <dynamic>[];
=======
=======
>>>>>>> cf8adcb... add test
  Future<List<dynamic>> checkRuns(RepositorySlug slug, String sha) async {
    final String path = '/repos/${slug.fullName}/commits/$sha/check-runs';
    final PaginationHelper paginationHelper = PaginationHelper(github);
<<<<<<< HEAD
    final List<dynamic> checkRuns = <dynamic>[];
>>>>>>> c913cd0... changed to check API
=======
    final List<dynamic> runStatus = <dynamic>[];
>>>>>>> cf8adcb... add test
    await for (Response response in paginationHelper.fetchStreamed('GET', path,
        headers: <String, String>{
          'Accept': 'application/vnd.github.antiope-preview+json'
        })) {
      final Map<String, dynamic> jsonStatus = json.decode(response.body);
<<<<<<< HEAD
<<<<<<< HEAD
      runStatus.addAll(jsonStatus['check_runs']);
    }
    return runStatus;
  }
}
<<<<<<< HEAD
=======
=======
>>>>>>> 627c61a... initial investigation
=======
      checkRuns.addAll(jsonStatus['check_runs']);
=======
      runStatus.addAll(jsonStatus['check_runs']);
>>>>>>> cf8adcb... add test
    }
    return runStatus;
  }
}
<<<<<<< HEAD
=======
>>>>>>> c913cd0... changed to check API
=======
>>>>>>> 73a3106... initial investigation
=======
>>>>>>> 2f3aef4... initial investigation
  String helper(String sha){
    return sha;
  }

  Future<List<dynamic>> checkRuns(
    RepositorySlug slug, String sha
  ) async {
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> changed to check API
    final String path = '/repos/${slug.fullName}/commits/$sha/check-runs';
    final PaginationHelper paginationHelper = PaginationHelper(github);
    final List<dynamic> runStatus = <dynamic>[];
    await for (Response response in paginationHelper.fetchStreamed('GET', path,
        headers: <String, String>{
          'Accept': 'application/vnd.github.antiope-preview+json'
        })) {
      final Map<String, dynamic> jsonStatus = json.decode(response.body);
      runStatus.addAll(jsonStatus['check_runs']);
    }
    return runStatus;
  }
}
<<<<<<< HEAD

=======
>>>>>>> 2f3aef4... initial investigation
<<<<<<< HEAD
>>>>>>> changed to check API
=======
=======

>>>>>>> cf8adcb... add test
>>>>>>> add test
=======
=======
  String helper(String sha) {
    return sha;
  }

  Future<List<dynamic>> checkRuns(RepositorySlug slug, String sha) async {
>>>>>>> 6617e07... changed to check API
    final String path = '/repos/${slug.fullName}/commits/$sha/check-runs';
    //final Response response = await github.request('GET', path,
    //    headers: <String, String>{
    //      'Accept': 'application/vnd.github.antiope-preview+json'
    //    });
    final PaginationHelper paginationHelper = PaginationHelper(github);
    final List<dynamic> checkRuns = <dynamic>[];
    await for (Response response in paginationHelper.fetchStreamed('GET', path,
        headers: <String, String>{
          'Accept': 'application/vnd.github.antiope-preview+json'
        })) {
      final Map<String, dynamic> jsonStatus = json.decode(response.body);
      checkRuns.addAll(jsonStatus['check_runs']);
    }
    return checkRuns;
  }
}
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> 627c61a... initial investigation
=======
>>>>>>> 2f3aef4... initial investigation
>>>>>>> c913cd0... changed to check API
=======
>>>>>>> 6617e07... changed to check API
=======
=======
>>>>>>> 2f3aef4... initial investigation
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
<<<<<<< HEAD
}
>>>>>>> 73a3106... initial investigation
=======
}
>>>>>>> 2f3aef4... initial investigation
=======

>>>>>>> cf8adcb... add test
