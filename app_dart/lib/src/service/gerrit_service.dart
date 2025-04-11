// Copyright 2020 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cocoon_server/logging.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';
import 'package:meta/meta.dart';

import '../model/gerrit/commit.dart';
import '../request_handling/exceptions.dart';
import 'config.dart';

/// Communicates with gerrit APIs https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html
/// to get information about projects hosted in Git on Borg.
interface class GerritService {
  GerritService({
    required Config config,
    required http.Client authClient,
    @visibleForTesting Duration? retryDelay,
  }) : _authClient = authClient,
       _retryDelay = retryDelay,
       _config = config;

  final Config _config;

  /// GoB replicas may not have all the Flutter state, and can require several retries
  final Duration? _retryDelay;

  /// Provider for generating a [http.Client] that is authenticated to make calls to GCP services.
  final http.Client _authClient;

  /// Gets the branches from a remote git repository using the gerrit APIs.
  ///
  /// [filterRegex] a regular expression string to filter the branches list to
  /// the ones matching the regex.
  ///
  /// See more:
  ///   * https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html#list-branches
  Future<List<String>> branches(
    String repo,
    String project, {
    String? filterRegex,
  }) async {
    final queryParameters = <String, String>{
      if (filterRegex != null && filterRegex.isNotEmpty) 'r': filterRegex,
    };
    final url = Uri.https(repo, 'projects/$project/branches', queryParameters);
    final response = await _getJson(url) as List<dynamic>;

    final branches = <String>[];

    final json = response.map((dynamic e) => e as Map<String, dynamic>);
    for (var element in json) {
      branches.add(element['ref'] as String);
    }

    return branches;
  }

  /// Gets the commit log for a project-branch pair.
  Future<Iterable<GerritCommit>> commits(
    RepositorySlug slug,
    String branch,
  ) async {
    final url = Uri.https(
      '${slug.owner}.googlesource.com',
      '${slug.name}/+log/refs/heads/$branch',
      <String, String>{'format': 'json'},
    );
    final response = await _getJson(url) as Map<String, dynamic>;
    final commitsJson = response['log'] as List<dynamic>;

    return commitsJson.map(
      (dynamic part) => GerritCommit.fromJson(part as Map<String, dynamic>),
    );
  }

  /// Finds a commit on a GoB mirror using the GitHub [slug] and commit [sha].
  ///
  /// The [slug] will be validated by checking if it represents a presubmit or postsubmit supported repo.
  Future<GerritCommit?> findMirroredCommit(
    RepositorySlug slug,
    String sha,
  ) async {
    if (!_config.supportedRepos.contains(slug)) return null;
    final gobMirrorName = 'mirrors/${slug.name}';
    return getCommit(RepositorySlug(slug.owner, gobMirrorName), sha);
  }

  /// Gets the commit info from Gob.
  ///
  /// See more:
  ///   * https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html#get-commit
  Future<GerritCommit?> getCommit(RepositorySlug slug, String commitId) async {
    // URL encode because "mirrors/flutter" should be "mirrors%2Fflutter".
    final projectName = Uri.encodeComponent(slug.name);
    // Uses [Uri] constructor instead of [Uri.https], where the latter uses [unencodedPath].
    // Our mirror repo, say [mirrors/cocoon], will not be encoded
    // as [mirrors%2Fcocoon] if injected directly. On the other hand, if we inject an encoded
    // version [mirrors%2Fcocoon], [Uri.https] will translate that to [mirrors%252Fcocoon].
    // Neither works with [Uri.https].
    final url = Uri(
      scheme: 'https',
      host: '${slug.owner}-review.googlesource.com',
      path: 'projects/$projectName/commits/$commitId',
    );
    log.info('Gerrit get-commit url: $url');

    final response = await _get(url, throwOnError: false);
    log.info('Gob commit response for commit $commitId: ${response.body}');
    if (!_responseIsAcceptable(response)) return null;

    final jsonBody = _stripXssToken(response.body);
    final json = jsonDecode(jsonBody) as Map<String, dynamic>;
    return GerritCommit.fromJson(json);
  }

  /// Strips magic prefix from response body.
  ///
  /// To prevent against Cross Site Script Inclusion (XSSI) attacks, the JSON response body starts with a magic prefix line that
  /// must be stripped before feeding the rest of the response body to a JSON parser. The magic prefix is ")]}'".
  String _stripXssToken(String body) {
    return body.replaceRange(0, 4, '');
  }

  /// Creates a new branch.
  ///
  /// See more:
  ///   * https://gerrit-review.googlesource.com/Documentation/rest-api-projects.html#create-branch
  Future<void> createBranch(
    RepositorySlug slug,
    String branchName,
    String revision,
  ) async {
    log.info('Creating branch $branchName at $revision');
    final url = Uri.https(
      '${slug.owner}-review.googlesource.com',
      'projects/${slug.name}/branches/$branchName',
    );
    final response = await _put(url, body: revision) as Map<String, dynamic>;
    log.info('$response');
    if (response['revision'] != revision) {
      throw const InternalServerError('Failed to create branch');
    }
    log.info('Created branch $branchName');
  }

  Future<Object?> _getJson(Uri url, {bool throwOnError = true}) async {
    final response = await _get(url, throwOnError: throwOnError);
    final jsonBody = _stripXssToken(response.body);
    return jsonDecode(jsonBody) as Object?;
  }

  Future<http.Response> _get(Uri url, {bool throwOnError = true}) async {
    final client = RetryClient(
      _authClient,
      when: (response) => !_responseIsAcceptable(response),
      delay: (attempt) => _retryDelay ?? const Duration(seconds: 1) * attempt,
    );
    final response = await client.get(url);
    if (throwOnError && !_responseIsAcceptable(response)) {
      throw InternalServerError(
        'Gerrit returned ${response.statusCode} which is not 200 or 202',
      );
    }
    return response;
  }

  Future<dynamic> _put(Uri url, {Object? body}) async {
    final client = RetryClient(
      _authClient,
      when: (response) => !_responseIsAcceptable(response),
      delay: (attempt) => _retryDelay ?? const Duration(seconds: 1) * attempt,
    );
    final response = await client.put(url, body: body);
    if (!_responseIsAcceptable(response)) {
      throw InternalServerError(
        'Gerrit returned ${response.statusCode} which is not 200 or 202',
      );
    }
    log.info('Sent PUT to $url');
    log.info(response.body);
    // Remove XSS token
    final jsonBody = _stripXssToken(response.body);
    log.info(jsonBody);
    return jsonDecode(jsonBody);
  }

  bool _responseIsAcceptable(http.BaseResponse response) =>
      response.statusCode == HttpStatus.ok ||
      response.statusCode == HttpStatus.accepted;
}
