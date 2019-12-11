// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:appengine/appengine.dart';
import 'package:gcloud/service_scope.dart' as ss;
import 'package:gcloud/db.dart';
import 'package:github/server.dart' hide createGitHubClient;
import 'package:github/server.dart' as gh show createGitHubClient;
import 'package:googleapis_auth/auth.dart';
import 'package:graphql/client.dart' hide Cache;
import 'package:googleapis/bigquery/v2.dart' as bigquery;
import 'package:meta/meta.dart';

import '../../cocoon_service.dart';
import '../model/appengine/service_account_info.dart';
import '../service/access_client_provider.dart';
import '../service/bigquery.dart';
import '../service/github_service.dart';

class Config {
  Config(this._db, this._cache) : assert(_db != null);

  final DatastoreDB _db;

  final CacheService _cache;

  @visibleForTesting
  static const String configCacheName = 'config';

  @visibleForTesting
  static const Duration configCacheTtl = Duration(hours: 12);

  Logging get loggingService => ss.lookup(#appengine.logging);

  Future<String> _getSingleValue(String id) async {
    /// First try and get the config value from the cache.
    final Uint8List cacheValue = await _cache.get(configCacheName, id);
    if (cacheValue != null) {
      return String.fromCharCodes(cacheValue);
    }

    /// On cache miss, load the config value from Datastore.
    final CocoonConfig cocoonConfig = CocoonConfig()
      ..id = id
      ..parentKey = _db.emptyKey;
    final CocoonConfig result =
        await _db.lookupValue<CocoonConfig>(cocoonConfig.key);

    /// Update the cache to have this value.
    await _cache.set(
      configCacheName,
      id,
      Uint8List.fromList(result.value.codeUnits),
      ttl: configCacheTtl,
    );

    return result.value;
  }

  Future<List<T>> _getJsonList<T>(String id) async {
    final String rawValue = await _getSingleValue(id);
    try {
      return json.decode(rawValue).cast<T>();
    } on FormatException {
      loggingService.error('Invalid JSON format for property "$id": $rawValue');
      throw InvalidConfigurationException(id);
    }
  }

  /// Per the docs in [DatastoreDB.withTransaction], only 5 entity groups can
  /// be touched in any given transaction, or the backing datastore will throw
  /// an error.
  int get maxEntityGroups => 5;

  DatastoreDB get db => _db;

  Future<String> get oauthClientId => _getSingleValue('OAuthClientId');

  Future<String> get githubOAuthToken => _getSingleValue('GitHubPRToken');

  Future<String> get nonMasterPullRequestMessage =>
      _getSingleValue('NonMasterPullRequestMessage');

  Future<String> get webhookKey => _getSingleValue('WebhookKey');

  Future<String> get missingTestsPullRequestMessage =>
      _getSingleValue('MissingTestsPullRequestMessage');

  Future<String> get goldenBreakingChangeMessage =>
      _getSingleValue('GoldenBreakingChangeMessage');

  Future<String> get goldenTriageMessage =>
      _getSingleValue('GoldenTriageMessage');

  Future<String> get forwardHost => _getSingleValue('ForwardHost');

  Future<int> get forwardPort => _getSingleValue('ForwardPort').then(int.parse);

  Future<String> get forwardScheme => _getSingleValue('ForwardScheme');

  Future<int> get maxTaskRetries =>
      _getSingleValue('MaxTaskRetries').then(int.parse);

  Future<String> get cqLabelName => _getSingleValue('CqLabelName');

  /// The name of the subcache in the Redis instance that stores responses.
  Future<String> get redisResponseSubcache =>
      _getSingleValue('RedisResponseSubcache');

  Future<String> get waitingForTreeToGoGreenLabelName =>
      _getSingleValue('WaitingForTreeToGreenLabelName');

  Future<ServiceAccountInfo> get deviceLabServiceAccount async {
    final String rawValue = await _getSingleValue('DevicelabServiceAccount');
    return ServiceAccountInfo.fromJson(json.decode(rawValue));
  }

  Future<ServiceAccountCredentials> get taskLogServiceAccount async {
    final String rawValue = await _getSingleValue('TaskLogServiceAccount');
    return ServiceAccountCredentials.fromJson(json.decode(rawValue));
  }

  /// A List of builders, i.e.:
  ///
  /// ```json
  /// [
  ///   {"name": "Linux", "repo": "flutter", "taskName": "linux_bot"},
  ///   {"name": "Mac", "repo": "flutter", "taskName": "mac_bot"},
  ///   {"name": "Windows", "repo": "flutter", "taskName": "windows_bot"},
  ///   {"name": "Linux Coverage", "repo": "flutter"},
  ///   {"name": "Linux Host Engine", "repo": "engine"},
  ///   {"name": "Linux Android AOT Engine", "repo": "engine"},
  ///   {"name": "Linux Android Debug Engine", "repo": "engine"},
  ///   {"name": "Mac Host Engine", "repo": "engine"},
  ///   {"name": "Mac Android AOT Engine", "repo": "engine"},
  ///   {"name": "Mac Android Debug Engine", "repo": "engine"},
  ///   {"name": "Mac iOS Engine", "repo": "engine"},
  ///   {"name": "Windows Host Engine", "repo": "engine"},
  ///   {"name": "Windows Android AOT Engine", "repo": "engine"}
  /// ]
  /// ```
  Future<List<Map<String, dynamic>>> get luciBuilders =>
      _getJsonList<Map<String, dynamic>>('LuciBuilders');

  /// A List of try builders, i.e.:
  ///
  /// ```json
  /// [
  ///   {"name": "Linux", "repo": "flutter", "taskName": "linux_bot"},
  ///   {"name": "Mac", "repo": "flutter", "taskName": "mac_bot"},
  ///   {"name": "Windows", "repo": "flutter", "taskName": "windows_bot"},
  ///   {"name": "Linux Coverage", "repo": "flutter"},
  ///   {"name": "Linux Host Engine", "repo": "engine"},
  ///   {"name": "Linux Android AOT Engine", "repo": "engine"},
  ///   {"name": "Linux Android Debug Engine", "repo": "engine"},
  ///   {"name": "Mac Host Engine", "repo": "engine"},
  ///   {"name": "Mac Android AOT Engine", "repo": "engine"},
  ///   {"name": "Mac Android Debug Engine", "repo": "engine"},
  ///   {"name": "Mac iOS Engine", "repo": "engine"},
  ///   {"name": "Windows Host Engine", "repo": "engine"},
  ///   {"name": "Windows Android AOT Engine", "repo": "engine"}
  /// ]
  /// ```
  Future<List<Map<String, dynamic>>> get luciTryBuilders =>
      _getJsonList<Map<String, dynamic>>('LuciTryBuilders');

  Future<GitHub> createGitHubClient() async {
    final String githubToken = await githubOAuthToken;
    return gh.createGitHubClient(
      auth: Authentication.withToken(githubToken),
    );
  }

  Future<GraphQLClient> createGitHubGraphQLClient() async {
    final HttpLink httpLink = HttpLink(
      uri: 'https://api.github.com/graphql',
    );

    final String token = await githubOAuthToken;
    final AuthLink _authLink = AuthLink(
      getToken: () async => 'Bearer $token',
    );

    final Link link = _authLink.concat(httpLink);

    return GraphQLClient(
      cache: InMemoryCache(),
      link: link,
    );
  }

  Future<bigquery.TabledataResourceApi> createTabledataResourceApi() async {
    final AccessClientProvider accessClientProvider =
        AccessClientProvider(await deviceLabServiceAccount);
    return await BigqueryService(accessClientProvider).defaultTabledata();
  }

  Future<GithubService> createGithubService() async {
    final GitHub github = await createGitHubClient();
    return GithubService(github);
  }
}

@Kind(name: 'CocoonConfig', idType: IdType.String)
class CocoonConfig extends Model {
  @StringProperty(propertyName: 'ParameterValue')
  String value;
}

class InvalidConfigurationException implements Exception {
  const InvalidConfigurationException(this.id);

  final String id;

  @override
  String toString() => 'Invalid configuration value for $id';
}
