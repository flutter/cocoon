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
    final Uint8List cacheValue = await _cache.getOrCreate(
      configCacheName,
      id,
      createFn: () => _getValueFromDatastore(id),
      ttl: configCacheTtl,
    );

    return String.fromCharCodes(cacheValue);
  }

  Future<Uint8List> _getValueFromDatastore(String id) async {
    final CocoonConfig cocoonConfig = CocoonConfig()
      ..id = id
      ..parentKey = _db.emptyKey;
    final CocoonConfig result =
        await _db.lookupValue<CocoonConfig>(cocoonConfig.key);

    return Uint8List.fromList(result.value.codeUnits);
  }

  /// Per the docs in [DatastoreDB.withTransaction], only 5 entity groups can
  /// be touched in any given transaction, or the backing datastore will throw
  /// an error.
  int get maxEntityGroups => 5;

  DatastoreDB get db => _db;

  Future<String> get oauthClientId => _getSingleValue('OAuthClientId');

  Future<String> get githubOAuthToken => _getSingleValue('GitHubPRToken');

  String get nonMasterPullRequestMessage => 'This pull request was opened '
      'against a branch other than _master_. Since Flutter pull requests should '
      'not normally be opened against branches other than master, I have changed '
      'the base to master. If this was intended, you may modify the base back to '
      '{{branch}}. See the [Release Process]'
      '(https://github.com/flutter/flutter/wiki/Release-process) for information '
      'about how other branches get updated.\n\n'
      '__Reviewers__: Use caution before merging pull requests to branches other '
      'than master. The circumstances where this is valid are very rare.\n\n'
      '/cc @dnfield';

  Future<String> get webhookKey => _getSingleValue('WebhookKey');

  String get missingTestsPullRequestMessage => 'It looks like this pull '
      'request may not have tests. Please make sure to add tests before merging. '
      'If you need an exemption to this rule, contact Hixie.\n\n'
      '__Reviewers__: Read the [Tree Hygiene page]'
      '(https://github.com/flutter/flutter/wiki/Tree-hygiene#how-to-review-code) '
      'and make sure this patch meets those guidelines before LGTMing.';

  String get goldenBreakingChangeMessage => 'It looks like this pull request '
      'includes a golden file change. Please make sure to follow '
      '[Handling Breaking Changes](https://github.com/flutter/flutter/wiki/Tree-hygiene#handling-breaking-changes). '
      'While there are exceptions to this rule, if this patch modifies an existing '
      'golden file, it is probably not an exception. Only new golden files are not '
      'considered breaking changes.\n\n'
      '[Writing a golden file test for `package:flutter`](https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter) '
      'may also provide guidance for this change.\n\n'
      '__Reviewers__: Read the [Tree Hygiene page](https://github.com/flutter/flutter/wiki/Tree-hygiene#how-to-review-code) '
      'and make sure this patch meets those guidelines before LGTMing.';

  String get goldenTriageMessage => 'Nice merge! 🎉\n'
      'It looks like this PR made changes to golden files. If these changes have '
      ' not been triaged as a tryjob, be sure to visit '
      '[Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter) '
      'to triage the results when post-submit testing has completed. The status '
      'of these tests can be seen on the '
      '[Flutter Dashboard](https://flutter-dashboard.appspot.com/build.html).\n'
      'Also, be sure to include this change in the [Changelog](https://github.com/flutter/flutter/wiki/Changelog).\n\n'
      'For more information about working with golden files, see the wiki page '
      '[Writing a Golden File Test for package:flutter/flutter](https://github.com/flutter/flutter/wiki/Writing-a-golden-file-test-for-package:flutter).';

  int get maxTaskRetries => 2;

  String get cqLabelName => 'CQ+1';

  String get waitingForTreeToGoGreenLabelName => 'waiting for tree to go green';

  Future<ServiceAccountInfo> get deviceLabServiceAccount async {
    final String rawValue = await _getSingleValue('DevicelabServiceAccount');
    return ServiceAccountInfo.fromJson(json.decode(rawValue));
  }

  Future<ServiceAccountCredentials> get taskLogServiceAccount async {
    final String rawValue = await _getSingleValue('TaskLogServiceAccount');
    return ServiceAccountCredentials.fromJson(json.decode(rawValue));
  }

  /// A List of builders for LUCI
  List<Map<String, dynamic>> get luciBuilders => <Map<String, String>>[
        <String, String>{
          'name': 'Linux',
          'repo': 'flutter',
          'taskName': 'linux_bot',
        },
        <String, String>{
          'name': 'Mac',
          'repo': 'flutter',
          'taskName': 'mac_bot',
        },
        <String, String>{
          'name': 'Windows',
          'repo': 'flutter',
          'taskName': 'windows_bot',
        },
        <String, String>{
          'name': 'Linux Coverage',
          'repo': 'flutter',
        },
        <String, String>{
          'name': 'Linux Host Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Linux Fuchsia',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Linux Android AOT Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Linux Android Debug Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Mac Host Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Mac Android AOT Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Mac Android Debug Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Mac iOS Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Mac iOS Engine Profile',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Mac iOS Engine Release',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Windows Host Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Windows Android AOT Engine',
          'repo': 'engine',
        }
      ];

  /// A List of try builders for LUCI
  List<Map<String, dynamic>> get luciTryBuilders => <Map<String, String>>[
        <String, String>{
          'name': 'Cocoon',
          'repo': 'cocoon',
        },
        <String, String>{
          'name': 'Linux',
          'repo': 'flutter',
          'taskName': 'linux_bot',
        },
        <String, String>{
          'name': 'Windows',
          'repo': 'flutter',
          'taskName': 'windows_bot',
        },
        <String, String>{
          'name': 'Linux Host Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Linux Fuchsia',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Linux Android AOT Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Linux Android Debug Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Windows Host Engine',
          'repo': 'engine',
        },
        <String, String>{
          'name': 'Windows Android AOT Engine',
          'repo': 'engine',
        }
      ];

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
