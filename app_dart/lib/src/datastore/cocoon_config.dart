// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:gcloud/db.dart';
import 'package:github/server.dart' hide createGitHubClient;
import 'package:github/server.dart' as gh show createGitHubClient;
import 'package:meta/meta.dart';

import '../model/appengine/service_account_info.dart';

@immutable
class Config {
  const Config(this._db) : assert(_db != null);

  final DatastoreDB _db;

  Future<String> _getSingleValue(String id) async {
    final CocoonConfig cocoonConfig = CocoonConfig()
      ..id = id
      ..parentKey = _db.emptyKey;
    final CocoonConfig result = await _db.lookupValue<CocoonConfig>(cocoonConfig.key);
    return result.value;
  }

  /// Per the docs in [DatastoreDB.withTransaction], only 5 entity groups can
  /// be touched in any given transaction, or the backing datastore will throw
  /// an error.
  int get maxEntityGroups => 5;

  DatastoreDB get db => _db;

  Future<String> get githubOAuthToken => _getSingleValue('GitHubPRToken');

  Future<String> get nonMasterPullRequestMessage => _getSingleValue('NonMasterPullRequestMessage');

  Future<String> get webhookKey => _getSingleValue('WebhookKey');

  Future<String> get missingTestsPullRequestMessage =>
      _getSingleValue('MissingTestsPullRequestMessage');

  Future<String> get goldenBreakingChangeMessage => _getSingleValue('GoldenBreakingChangeMessage');

  Future<String> get forwardHost => _getSingleValue('ForwardHost');

  Future<int> get forwardPort => _getSingleValue('ForwardPort').then(int.parse);

  Future<String> get forwardScheme => _getSingleValue('ForwardScheme');

  Future<int> get maxTaskRetries => _getSingleValue('MaxTaskRetries').then(int.parse);

  Future<String> get cqLabelName => _getSingleValue('CqLabelName');

  Future<ServiceAccountInfo> get deviceLabServiceAccount async {
    final String rawValue = await _getSingleValue('DevicelabServiceAccount');
    return ServiceAccountInfo.fromJson(json.decode(rawValue));
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
  Future<List<Map<String, dynamic>>> get luciBuilders async {
    final String rawValue = await _getSingleValue('LuciBuilders');
    return json.decode(rawValue).cast<Map<String, dynamic>>();
  }

  Future<GitHub> createGitHubClient() async {
    final String githubToken = await githubOAuthToken;
    return gh.createGitHubClient(
      auth: Authentication.withToken(githubToken),
    );
  }
}

@Kind(name: 'CocoonConfig', idType: IdType.String)
class CocoonConfig extends Model {
  @StringProperty(propertyName: 'ParameterValue')
  String value;
}
