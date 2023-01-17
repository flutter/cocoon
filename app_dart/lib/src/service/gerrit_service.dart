// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:cocoon_service/src/request_handling/exceptions.dart';
import 'package:github/github.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:meta/meta.dart';

import '../model/gerrit/commit.dart';
import 'config.dart';
import 'logging.dart';

/// Communicates with gerrit APIs https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html
/// to get information about projects hosted in Git on Borg.
class GerritService {
  GerritService({
    required this.config,
    http.Client? httpClient,
    @visibleForTesting this.authClientProvider = clientViaApplicationDefaultCredentials,
    @visibleForTesting this.retryDelay,
  }) : httpClient = httpClient ?? http.Client();

  final Config config;
  final http.Client httpClient;

  final Duration? retryDelay;

  /// Provider for generating a [http.Client] that is authenticated to make calls to GCP services.
  final Future<AutoRefreshingAuthClient> Function({
    http.Client? baseClient,
    required List<String> scopes,
  }) authClientProvider;

  /// Gets the branches from a remote git repository using the gerrit APIs.
  ///
  /// [filterRegex] a regular expression string to filter the branches list to
  /// the ones matching the regex.
  ///
  /// See more:
  ///   * https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html#list-branches
  Future<List<String>> branches(String repo, String project, {String? filterRegex}) async {
    final Map<String, String> queryParameters = <String, String>{
      if (filterRegex != null && filterRegex.isNotEmpty) 'r': filterRegex,
    };
    final Uri url = Uri.https(repo, 'projects/$project/branches', queryParameters);
    final List<dynamic> response = await _getJson(url) as List<dynamic>;

    final List<String> branches = <String>[];

    final Iterable<Map<String, dynamic>> json = response.map((dynamic e) => e as Map<String, dynamic>);
    for (Map<String, dynamic> element in json) {
      branches.add(element['ref'] as String);
    }

    return branches;
  }

  /// Gets the commit log for a project-branch pair.
  Future<Iterable<GerritCommit>> commits(RepositorySlug slug, String branch) async {
    final Uri url =
        Uri.https('${slug.owner}.googlesource.com', '${slug.name}/+log/refs/heads/$branch', <String, String>{
      'format': 'json',
    });
    final Map<String, dynamic> response = await _getJson(url) as Map<String, dynamic>;
    final List<dynamic> commitsJson = response['log'] as List<dynamic>;

    return commitsJson.map((dynamic part) => GerritCommit.fromJson(part as Map<String, dynamic>));
  }

  /// Gets the info for a commit from a remote git repository using the gerrit APIs.
  ///
  /// See more:
  ///   * https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html#get-commit
  Future<GerritCommit?> getCommit(RepositorySlug slug, String commitId) async {
    // URL encode because "mirrors/flutter" should be "mirrors%2Fflutter".
    final String projectName = Uri.encodeComponent(slug.name);
    final Uri url = Uri.https('${slug.owner}-review.googlesource.com', 'projects/$projectName/commits/$commitId');

    final http.Response response = await _get(url);
    if (response.statusCode == 404) return null;

    // TODO: use _responseIsAcceptable check?
    final String jsonBody = _stripXssToken(response.body);
    final json = jsonDecode(jsonBody) as Map<String, dynamic>;
    return GerritCommit.fromJson(json);
  }

  /// Creates a new branch.
  ///
  /// See more:
  ///   * https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html#create-branch
  Future<void> createBranch(RepositorySlug slug, String branchName, String revision) async {
    log.info('Creating branch $branchName at $revision');
    final Uri url = Uri.https('${slug.owner}-review.googlesource.com', 'projects/${slug.name}/branches/$branchName');
    final Map<String, dynamic> response = await _put(
      url,
      body: revision,
    ) as Map<String, dynamic>;
    log.info(response);
    if (response['revision'] != revision) {
      throw const InternalServerError('Failed to create branch');
    }
    log.info('Created branch $branchName');
  }

  /// Find a commit on a GoB mirror using the GitHub [slug] and commit [sha].
  ///
  /// The [slug] will be validated by checking if [Config.postsubmitSupportedRepos] includes it.
  Future<GerritCommit?> findMirroredCommit(RepositorySlug slug, String sha) async {
    if (!config.postsubmitSupportedRepos.contains(slug)) return null;
    final gobMirrorName = 'mirrors/${slug.name}';
    return await getCommit(RepositorySlug(slug.owner, gobMirrorName), sha);
  }

  /// To prevent against Cross Site Script Inclusion (XSSI) attacks, the JSON response body starts with a magic prefix line that
  /// must be stripped before feeding the rest of the response body to a JSON parser. The magic prefix is ")]}'".
  String _stripXssToken(String body) {
    return body.replaceRange(0, 4, '');
  }

  Future<http.Response> _get(Uri url) async {
    final RetryClient client = RetryClient(httpClient);
    return await client.get(url);
  }

  Future<dynamic> _getJson(Uri url) async {
    final RetryClient client = RetryClient(httpClient);
    final http.Response response = await client.get(url);

    final String jsonBody = _stripXssToken(response.body);
    return jsonDecode(jsonBody) as dynamic;
  }

  Future<dynamic> _put(
    Uri url, {
    Object? body,
  }) async {
    final http.Client authClient = await authClientProvider(baseClient: httpClient, scopes: <String>[]);
    // GoB replicas may not have all the Flutter state, and can require several retries
    final http.Client client = RetryClient(
      authClient,
      when: (http.BaseResponse response) => _responseIsAcceptable(response) == false,
      delay: (int attempt) => retryDelay ?? const Duration(seconds: 1) * attempt,
    );
    final http.Response response = await client.put(
      url,
      body: body,
    );
    if (_responseIsAcceptable(response) == false) {
      throw InternalServerError('Gerrit returned ${response.statusCode} which is not 200 or 202');
    }
    log.info('Sent PUT to $url');
    log.info(response.body);
    final String jsonBody = _stripXssToken(response.body);
    log.info(jsonBody);
    return jsonDecode(jsonBody);
  }

  bool _responseIsAcceptable(http.BaseResponse response) =>
      response.statusCode == HttpStatus.ok || response.statusCode == HttpStatus.accepted;
}
