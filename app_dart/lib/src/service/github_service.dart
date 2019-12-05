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
<<<<<<< HEAD
class GithubService {
=======
<<<<<<< HEAD
=======
>>>>>>> c913cd0... changed to check API
=======
class GithubService {
=======
=======
>>>>>>> 8b065a0e0074c947bbbed1a9909a673781e6ba4f
<<<<<<< HEAD
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
class GithubService {
=======
class GithubService{

>>>>>>> 2f3aef4... initial investigation
<<<<<<< HEAD
>>>>>>> changed to check API
=======
<<<<<<< HEAD
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
=======
=======
class GithubService {
>>>>>>> 5660acf1acd1319b9816fae6b1352363f1da110e
>>>>>>> 8b065a0e0074c947bbbed1a9909a673781e6ba4f
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
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
<<<<<<< HEAD
=======
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
  Future<List<dynamic>> checkRuns(RepositorySlug slug, String sha) async {
=======
=======
>>>>>>> add test
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> c913cd0... changed to check API
=======
=======
>>>>>>> 8b065a0e0074c947bbbed1a9909a673781e6ba4f
<<<<<<< HEAD
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
  String helper(String sha) {
    return sha;
  }

<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
=======
>>>>>>> cf8adcb... add test
  Future<List<dynamic>> checkRuns(RepositorySlug slug, String sha) async {
    final String path = '/repos/${slug.fullName}/commits/$sha/check-runs';
    final PaginationHelper paginationHelper = PaginationHelper(github);
    final List<dynamic> runStatus = <dynamic>[];
<<<<<<< HEAD
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
=======
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
    await for (Response response in paginationHelper.fetchStreamed('GET', path,
        headers: <String, String>{
          'Accept': 'application/vnd.github.antiope-preview+json'
        })) {
      final Map<String, dynamic> jsonStatus = json.decode(response.body);
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
      runStatus.addAll(jsonStatus['check_runs']);
    }
    return runStatus;
  }
}
<<<<<<< HEAD
=======
<<<<<<< HEAD
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
=======
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
  String helper(String sha){
    return sha;
  }

  Future<List<dynamic>> checkRuns(
    RepositorySlug slug, String sha
  ) async {
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> changed to check API
=======
>>>>>>> changed to check API
=======
=======
  Future<List<dynamic>> checkRuns(RepositorySlug slug, String sha) async {
>>>>>>> 5660acf1acd1319b9816fae6b1352363f1da110e
>>>>>>> 8b065a0e0074c947bbbed1a9909a673781e6ba4f
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
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
<<<<<<< HEAD
=======
<<<<<<< HEAD
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485

=======
>>>>>>> 2f3aef4... initial investigation
<<<<<<< HEAD
>>>>>>> changed to check API
=======
=======

>>>>>>> cf8adcb... add test
>>>>>>> add test
=======
<<<<<<< HEAD
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
=======
>>>>>>> 2f3aef4... initial investigation
=======

>>>>>>> cf8adcb... add test
=======

>>>>>>> 5660acf1acd1319b9816fae6b1352363f1da110e
>>>>>>> 8b065a0e0074c947bbbed1a9909a673781e6ba4f
>>>>>>> 0566862076413d185a26ae5bc48d94df11814485
